//
//  ServicePlanDataServiceTests.swift
//  ProtonCore-Payments-Tests - Created on 21/12/2020.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
import StoreKit
#if canImport(ProtonCoreTestingToolkitUnitTestsPayments)
import ProtonCoreTestingToolkitUnitTestsDataModel
import ProtonCoreTestingToolkitUnitTestsPayments
import ProtonCoreTestingToolkitUnitTestsServices
#else
import ProtonCoreTestingToolkit
#endif
import ProtonCoreNetworking
import ProtonCoreDataModel
@testable import ProtonCorePayments

final class ServicePlanDataServiceTests: XCTestCase {

    let timeout = 1.0

    var paymentsApi: PaymentsApiMock!
    var apiService: APIServiceMock!
    var alertManagerMock: AlertManagerMock!
    var paymentsAlertMock: PaymentsAlertManager!
    var paymentsQueue: SKPaymentQueueMock!
    // swiftlint:disable:next weak_delegate
    var storeKitManagerDelegate: StoreKitManagerDelegateMock!
    var paymentTokenStorageMock: PaymentTokenStorageMock!
    var servicePlanDataStorageMock: ServicePlanDataStorageMock!

    var testSubscriptionDict: [String: Any] {
        [
            "Code": 1000,
            "Subscription": [
                "PeriodStart": 0,
                "PeriodEnd": 0,
                "CouponCode": "test code",
                "Cycle": 12,
                "Plans": []
            ]
        ]
    }

    var testCountriesCountDict: [String: Any] {
        [
            "Code": 1000,
            "Counts": [
                [
                    "MaxTier": 0,
                    "Count": 4
                ],
                [
                    "MaxTier": 1,
                    "Count": 31
                ],
                [
                    "MaxTier": 2,
                    "Count": 52
                ]
            ]
        ]
    }

    let testUser = User(
        ID: "12345",
        name: "test",
        usedSpace: 0,
        usedBaseSpace: 0,
        usedDriveSpace: 0,
        currency: "CHF",
        credit: 12300,
        maxSpace: 100000,
        maxBaseSpace: 50000,
        maxDriveSpace: 50000,
        maxUpload: 100000,
        role: 0,
        private: 1,
        subscribed: [],
        services: 0,
        delinquent: 0,
        orgPrivateKey: nil,
        email: "test@user.ch",
        displayName: "test",
        keys: []
    )

    override func setUp() {
        super.setUp()
        paymentsApi = PaymentsApiMock()
        apiService = APIServiceMock()
        alertManagerMock = AlertManagerMock()
        paymentsAlertMock = PaymentsAlertManager(alertManager: alertManagerMock)
        paymentsQueue = SKPaymentQueueMock()
        storeKitManagerDelegate = StoreKitManagerDelegateMock()
        paymentTokenStorageMock = PaymentTokenStorageMock()
        servicePlanDataStorageMock = ServicePlanDataStorageMock()
    }

    func testUpdateServicePlansNoneAvailable() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { [] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        // statusRequest
        // plansRequest
        // defaultPlanRequest
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/status") {
                completion(nil, .success(["Code": 1000, "Apple": true]))
            } else if path.contains("/plans/default") {
                completion(nil, .success(Plan.empty.toSuccessfulResponse(underKey: "Plans")))
            } else if path.contains("/plans") {
                completion(nil, .success([Plan.empty].toSuccessfulResponse(underKey: "Plans")))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateServicePlans {
            expectation.fulfill()
        } failure: { error in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
        XCTAssertEqual(out.availablePlansDetails, [])
        XCTAssertEqual(out.defaultPlanDetails, Plan.empty)
    }

    func testUpdateServicePlansSomeAvailable() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        // statusRequest
        // plansRequest
        // defaultPlanRequest
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/status") {
                completion(nil, .success(["Code": 1000, "Apple": true]))
            } else if path.contains("/plans/default") {
                completion(nil, .success(Plan.empty.updated(name: "free").toSuccessfulResponse(underKey: "Plans")))
            } else if path.contains("/plans") {
                completion(nil, .success([Plan.empty.updated(name: "test", cycle: 12)].toSuccessfulResponse(underKey: "Plans")))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateServicePlans {
            expectation.fulfill()
        } failure: { error in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
        XCTAssertEqual(out.availablePlansDetails, [Plan.empty.updated(name: "test", cycle: 12)])
        XCTAssertEqual(out.defaultPlanDetails, Plan.empty.updated(name: "free"))
    }

    func testUpdateServicePlansSomeAvailableDifferentPeriods() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["iosvpn_vpn2022_12_usd_non_renewing", "iosvpn_bundle2022_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        // statusRequest
        // plansRequest
        // defaultPlanRequest
        // Expected result: only matched plans with a period of 12 should be mapped to the output availablePlansDetails

        let priceVpn2022 = 105
        let priceBundle2022 = 150
        let yearlySubscriptionCycleReturnedByBE = 12
        let yearlySubscriptionCyclePresentedToUser = 12

        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/status") {
                completion(nil, .success(["Code": 1000, "Apple": true]))
            } else if path.contains("/plans/default") {
                completion(nil, .success(Plan.empty.updated(name: "free").toSuccessfulResponse(underKey: "Plans")))
            } else if path.contains("/plans") {
                completion(nil, .success([

                    // pricing [numberOfMonths, price]
                    Plan.empty.updated(name: "vpn2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceVpn2022], cycle: 13),
                    Plan.empty.updated(name: "vpn2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceVpn2022], cycle: 15),
                    Plan.empty.updated(name: "vpn2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceVpn2022], cycle: 18),
                    Plan.empty.updated(name: "bundle2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceBundle2022], cycle: 13),
                    Plan.empty.updated(name: "bundle2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceBundle2022], cycle: 18),
                    Plan.empty.updated(name: "bundle2022", pricing: [String(yearlySubscriptionCycleReturnedByBE): priceBundle2022], cycle: yearlySubscriptionCycleReturnedByBE)
                ].toSuccessfulResponse(underKey: "Plans")))
            } else {
                XCTFail("Path doesn't match any available paths")
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateServicePlans {
            expectation.fulfill()
        } failure: { error in
            XCTFail(error.localizedDescription)
        }
        waitForExpectations(timeout: timeout)
        XCTAssertEqual(out.availablePlansDetails, [Plan.empty.updated(name: "bundle2022", pricing: [String(yearlySubscriptionCyclePresentedToUser): priceBundle2022], cycle: yearlySubscriptionCyclePresentedToUser)])
        XCTAssertEqual(out.defaultPlanDetails, Plan.empty.updated(name: "free"))
    }

    func testUpdateCurrentSubscriptionExists() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        // getUsersRequest
        // getSubscriptionRequest
        // organizationsRequest
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: .mail) }
        let testSubscriptionDict = self.testSubscriptionDict
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/subscription") {
                completion(nil, .success(testSubscriptionDict))
            } else if path.contains("/organizations") {
                completion(nil, .success(Organization.dummy.toSuccessfulResponse(underKey: "Organization")))
            } else if path.contains("/methods") {
                completion(nil, .success(["Code": 1000, "PaymentMethods": []]))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateCurrentSubscription {
            expectation.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
        XCTAssertEqual(out.currentSubscription?.organization, Organization.dummy)
        XCTAssertEqual(out.currentSubscription?.couponCode, "test code")
    }

    func testUpdateCurrentSubscriptionNoSubscription() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: []) }
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/subscription") {
                completion(nil, .success(["Code": 22110]))
            } else if path.contains("/methods") {
                completion(nil, .success(["Code": 1000, "PaymentMethods": []]))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateCurrentSubscription {
            expectation.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
        XCTAssertNotNil(out.currentSubscription)
        XCTAssertNotNil(out.credits)
    }

    func testUpdateCurrentSubscriptionNoAccess() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: .mail) }
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/subscription") {
                completion(URLSessionDataTaskMock(response: HTTPURLResponse(statusCode: 403)),
                           .failure(NSError(domain: "test", code: 100, userInfo: nil)))
            } else if path.contains("/methods") {
                completion(nil, .success(["Code": 1000, "PaymentMethods": []]))
            } else {
                XCTFail()
            }
        }
        let asd = self.expectation(description: "Success completion block called")
        out.updateCurrentSubscription {
            asd.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
        XCTAssertTrue(out.currentSubscription!.isEmptyBecauseOfUnsufficientScopeToFetchTheDetails)
        XCTAssertNil(out.credits)
    }

    func testupdateCreditsSuccess() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: []) }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateCredits {
            XCTAssertEqual(out.credits?.currency, "CHF")
            XCTAssertEqual(out.credits?.credit, 123)
            expectation.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
    }

    func testUpdateCountriesCountSuccess() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: []) }
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/vpn/countries/count") {
                completion(nil, .success(self.testCountriesCountDict))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateCountriesCount {
            XCTAssertEqual(out.countriesCount?.count, 3)
            XCTAssertEqual(out.countriesCount?[0].maxTier, 0)
            XCTAssertEqual(out.countriesCount?[0].count, 4)
            XCTAssertEqual(out.countriesCount?[1].maxTier, 1)
            XCTAssertEqual(out.countriesCount?[1].count, 31)
            XCTAssertEqual(out.countriesCount?[2].maxTier, 2)
            XCTAssertEqual(out.countriesCount?[2].count, 52)
            expectation.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
    }

    func testUpdateCountriesCountNoData() {
        let out = ServicePlanDataService(inAppPurchaseIdentifiers: { ["ios_test_12_usd_non_renewing"] },
                                         paymentsApi: paymentsApi,
                                         apiService: apiService,
                                         localStorage: servicePlanDataStorageMock,
                                         paymentsAlertManager: paymentsAlertMock)
        paymentsApi.getUserStub.bodyIs { _, _ in self.testUser.updated(subscribed: []) }
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            if path.contains("/vpn/countries/count") {
                completion(nil, .success(["Code": 1000, "Counts": []]))
            } else {
                XCTFail()
            }
        }
        let expectation = self.expectation(description: "Success completion block called")
        out.updateCountriesCount {
            XCTAssertEqual(out.countriesCount?.count, 0)
            expectation.fulfill()
        } failure: { _ in
            XCTFail()
        }
        waitForExpectations(timeout: timeout)
    }
}
