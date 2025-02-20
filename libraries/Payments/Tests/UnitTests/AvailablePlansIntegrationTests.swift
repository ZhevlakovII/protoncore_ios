//
//  AvailablePlansIntegrationTests.swift
//  ProtonCorePaymentsTests - Created on 13.07.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

#if os(iOS)

import XCTest
import OHHTTPStubs

import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreLogin
import ProtonCoreServices
@testable import ProtonCorePayments

#if canImport(OHHTTPStubsSwift)
import OHHTTPStubsSwift
#endif

#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUnitTestsDoh
#else
import ProtonCoreTestingToolkit
#endif

final class AvailablePlansIntegrationTests: XCTestCase {
    func test_availablePlans_parsesCorrectly() {
        let api = PMAPIService.createAPIServiceWithoutSession(doh: DohMock() as DoHInterface, challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))

        mockAvailablePlans()

        let expectation = expectation(description: "test_availablePlans_parseCorrectly")
        let request = AvailablePlansRequest(api: api)

        Task {
            do {
                let availablePlansResponse = try await request.response(responseObject: AvailablePlansResponse())
                guard let availablePlans = availablePlansResponse.availablePlans else {
                    XCTFail("Expected: available plans")
                    return
                }

                expectation.fulfill()

                XCTAssertEqual(availablePlans.defaultCycle, 12)
                XCTAssertEqual(availablePlans.plans.count, 1)
                XCTAssertEqual(availablePlans.plans[0].title, "Mail Essentials")
                XCTAssertEqual(availablePlans.plans[0].name, "mailpro2022")
                XCTAssertEqual(availablePlans.plans[0].description, "Description")
                XCTAssertEqual(availablePlans.plans[0].decorations.count, 4)
                XCTAssertEqual(availablePlans.plans[0].decorations[0], .starred(.init(type: "starred", iconName: "tick")))
                XCTAssertEqual(availablePlans.plans[0].decorations[1], .border(.init(type: "border", color: "#xxx")))
                XCTAssertEqual(availablePlans.plans[0].decorations[2], .badge(.init(type: "badge", anchor: .title, text: "some text", planID: "some id")))
                XCTAssertEqual(availablePlans.plans[0].decorations[3], .badge(.init(type: "badge", anchor: .subtitle, text: "some text")))
                XCTAssertEqual(availablePlans.plans[0].instances[0].vendors?.apple.productID, "apple_some_random_id")
                XCTAssertEqual(availablePlans.plans[0].instances[0].cycle, 1)
                XCTAssertEqual(availablePlans.plans[0].instances[0].description, "for 1 month")
                XCTAssertEqual(availablePlans.plans[0].instances[0].price[0].current, 499)
                XCTAssertEqual(availablePlans.plans[0].entitlements.count, 1)
                XCTAssertEqual(availablePlans.plans[0].entitlements[0], .description(.init(type: "description", iconName: "tick", text: "text", hint: "hint")))
            } catch {
                XCTFail("Expected: available plans")
            }
        }

        wait(for: [expectation], timeout: 1)
    }
}

extension AvailablePlansIntegrationTests {
    private func mockAvailablePlans() {
        mock(filename: "AvailablePlans", title: "available plans /payment/v5/plans mock", path: "/payments/v5/plans")
    }

    private func mock(filename: String, title: String, path: String, statusCode: Int32 = 200) {
        weak var usersStub = stub(condition: pathEndsWith(path)) { request in
            let bundle = Bundle.module

            let url = bundle.url(forResource: filename, withExtension: "json")!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: try! Data(contentsOf: url), statusCode: statusCode, headers: headers)
        }

        usersStub?.name = title
    }
}

#endif
