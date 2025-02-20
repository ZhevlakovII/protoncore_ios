//
//  HumanVerificationAPITests.swift
//  ProtonCore-APIClient-Tests - Created on 13/11/20.
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

#if os(iOS)

import XCTest

import OHHTTPStubs
#if canImport(OHHTTPStubsSwift)
import OHHTTPStubsSwift
#endif
import ProtonCoreChallenge
import ProtonCoreLog
import ProtonCoreDoh
import ProtonCoreNetworking
import ProtonCoreServices
#if canImport(ProtonCoreTestingToolkitUnitTestsAuthentication)
import ProtonCoreTestingToolkitTestData
import ProtonCoreTestingToolkitUnitTestsAuthentication
import ProtonCoreTestingToolkitUnitTestsDoh
#else
import ProtonCoreTestingToolkit
#endif
@testable import ProtonCoreAPIClient

class HumanVerificationAPITests: XCTestCase {

    override func setUp() {
        super.setUp()
        HTTPStubs.setEnabled(true)
        HTTPStubs.onStubActivation { request, descriptor, response in }

        // get code stub
        stub(condition: isMethodPOST() && isPath("/api/users/code")) { request in
            let body = request.ohhttpStubs_httpBody!
            let resultBody: Data
            do {
                let dict = try JSONSerialization.jsonObject(with: body, options: []) as! [String: Any]
                if let value = dict["Type"] as? String, value == "email" || value == "sms", let dest = dict["Destination"] as? [String: Any] {
                    if let address = dest["Address"] as? String {
                        if address == "test@test.ch" {
                            resultBody = self.responseStringSuccess.data(using: String.Encoding.utf8)!
                        } else {
                            resultBody = self.responseStringInvalidEmailError.data(using: String.Encoding.utf8)!
                        }
                    } else if let phone = dest["Phone"] as? String {
                        if phone == "+41000000000" {
                            resultBody = self.responseStringSuccess.data(using: String.Encoding.utf8)!
                        } else {
                            resultBody = self.responseStringInvalidPhoneNumberError.data(using: String.Encoding.utf8)!
                        }
                    } else {
                        resultBody = self.responseStringCodeTypeError.data(using: String.Encoding.utf8)!
                    }
                } else {
                    resultBody = self.responseStringCodeTypeError.data(using: String.Encoding.utf8)!
                }
            } catch {
                resultBody = self.responseStringCodeTypeError.data(using: String.Encoding.utf8)!
            }
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: resultBody, statusCode: 200, headers: headers)
        }
    }

    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    class TestAuthDelegate: AuthDelegate {
        func onSessionObtaining(credential: Credential) {}
        func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?, privateKey: String?) {}
        weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?
        var authCredential: AuthCredential? { testAuthCredential }
        func authCredential(sessionUID: String) -> AuthCredential? { testAuthCredential }
        func credential(sessionUID: String) -> Credential? { testAuthCredential.map(Credential.init) }
        func onAuthenticatedSessionInvalidated(sessionUID uid: String) { }
        func onUpdate(credential: Credential, sessionUID: String) { }
        func onRefresh(sessionUID: String, service: APIService, complete: @escaping AuthRefreshResultCompletion) { }
        func onUnauthenticatedSessionInvalidated(sessionUID: String) { }

        private var testAuthCredential: AuthCredential? {
            AuthCredential(sessionID: "sessionID", accessToken: "accessToken", refreshToken: "refreshToken", userName: "userName", userID: "userID", privateKey: nil, passwordKeySalt: nil)
        }
    }

    class TestAPIServiceDelegate: APIServiceDelegate {
        var locale: String { return "en_US" }
        func isReachable() -> Bool { return true }
        var userAgent: String? { return "" }
        func onUpdate(serverTime: Int64) { }
        var appVersion: String { return "ios-mail@4.2.0-dev" }
        var additionalHeaders: [String: String]?
        func onDohTroubleshot() {
            // swiftlint:disable:next no_print
            PMLog.info("\(#file): \(#function)")
        }
    }

    var responseString9001: String {
        return "{\"Error\": \"Human verification required\",\"Code\": 9001,\"Details\": {\"HumanVerificationMethods\": [\"captcha\",\"sms\",\"email\",\"payment\",\"invite\", \"coupon\"],\"HumanVerificationToken\": \"signup\",\"Title\": \"human verification in tests\"},\"ErrorDescription\": \"signup\"}"
    }

    var responseStringSuccess: String {
        return "{\"Code\": 1000}"
    }

    var responseStringVerificationError: String {
        return "{\"Error\": \"Invalid verification code\",\"Code\": 12087}"
    }

    var responseStringCodeTypeError: String {
        return "{\"Error\": \"Invalid verification code type\",\"Code\": 12213}"
    }

    var responseStringInvalidEmailError: String {
        return "{\"Error\": \"Invalid email address\",\"Code\": 12221}"
    }

    var responseStringInvalidPhoneNumberError: String {
        return "{\"Error\": \"Invalid phone number\",\"Code\": 12231}"
    }

    var captchaToken: String {
        return "l9WSVtEX/6be2XON24jVD+XtX/+LuSpIeJO/E+x05CV5ssEA03AGdBq26nlnViocsW7P-uOZHeGNlPExTyRDiaiqy8CStBSLLhWFEFFfbOxS5Ipk_E-LyfGVDjshD5eQo2Z2XcoM1HMibnIJpwa6adji-JZwoJHvfnccG9c4Y7CLfrr8CIUV1e_N-4Sd1WWzBZlKVVpM_ZHjHqUoXm-z09g7olwiLISbmVH27caRvI4KH6kNjq7YuSik7qkttd5dcAw3D5uakXKd-bTuOzMvsTGsMdd3-lnh_EAfVwCeBR0OvoJDRRM-YPlwS7mt5NYaTEMQV0xVh7KSiLSytnkdRveK7RnoLgucTyvqAr5biNHOr-Pdpm90XaK-YMXl2xuZJzOh_Pv9cIKkUbP5k4f-yso5DmogodW_dK7izHyMDkVG8hjmQA_QzIRhqW1PG0xLq6ZToTZxL8DgGHhOTX7Q"
    }

    var emailToken: String {
        return "test@test.com:666666"
    }

    var smsToken: String {
        return "+41000000000:666666"
    }

    func testSendCodeEmail() {
        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let route = UserAPI.Router.code(type: .email, receiver: "test@test.ch")
        api.perform(request: route, response: Response()) { (task, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testSendCodeSMS() {
        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let route = UserAPI.Router.code(type: .sms, receiver: "+41000000000")
        api.perform(request: route, response: Response()) { (task, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testSendCodeInvalidEmail() {
        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let route = UserAPI.Router.code(type: .email, receiver: "")
        api.perform(request: route, response: Response()) { (task, response) in
            XCTAssertEqual(response.responseCode, 12221)
            XCTAssert(response.error != nil)
            XCTAssert(response.error?.localizedDescription == "Invalid email address")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testSendCodeInvalidSMS() {
        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let route = UserAPI.Router.code(type: .sms, receiver: "")
        api.perform(request: route, response: Response()) { (task, response) in
            XCTAssertEqual(response.responseCode, 12231)
            XCTAssert(response.error != nil)
            XCTAssert(response.error?.localizedDescription == "Invalid phone number")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testHumanVerificationClose() {
        // backend answer when there is no verification token
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && !hasHeaderNamed("x-pm-human-verification-token")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate
        let testHumanVerifyDelegate = HumanCheckHelperMock(apiService: api, resultSuccess: false)
        api.humanDelegate = testHumanVerifyDelegate

        let client = TestApiClient(api: api)
        client.triggerHumanVerify { (_, response) in
            XCTAssert(response.error != nil)
            XCTAssertEqual(response.error?.responseCode, 9001)
            XCTAssert(response.error?.localizedDescription == "Human verification required")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testCaptchaMethodSuccess() {

        // backend answer when there is no verification token
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && !hasHeaderNamed("x-pm-human-verification-token")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // backend answer with verification token and verification token type
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && hasHeaderNamed("x-pm-human-verification-token", value: captchaToken) && hasHeaderNamed("x-pm-human-verification-token-type", value: "captcha") && hasHeaderNamed("Content-Type")) { request in
            let body = self.responseStringSuccess.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        let expectation = self.expectation(description: "Success completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let resultHeaders: [String: Any] = ["x-pm-human-verification-token": captchaToken, "x-pm-human-verification-token-type": "captcha"]
        let testHumanVerifyDelegate = HumanCheckHelperMock(apiService: api, resultSuccess: true, resultHeaders: [resultHeaders])
        api.humanDelegate = testHumanVerifyDelegate

        let client = TestApiClient(api: api)
        client.triggerHumanVerify { (_, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testEmailMethodSuccess() {
        // backend answer when there is no verification token
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && !hasHeaderNamed("x-pm-human-verification-token")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // backend answer with verification token and verification token type
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && hasHeaderNamed("x-pm-human-verification-token", value: emailToken) && hasHeaderNamed("x-pm-human-verification-token-type", value: "email") && hasHeaderNamed("Content-Type")) { request in
            let body = self.responseStringSuccess.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        let expectation1 = self.expectation(description: "Success send code completion block called testEmailMethodSuccess")
        let expectation2 = self.expectation(description: "Success verification completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let resultHeaders: [String: Any] = ["x-pm-human-verification-token": emailToken, "x-pm-human-verification-token-type": "email"]

        let testHumanVerifyDelegate = HumanCheckHelperMock(apiService: api, resultSuccess: true, resultHeaders: [resultHeaders]) { responseResult in
            // api request to send verification code to the email
            let route = UserAPI.Router.code(type: .email, receiver: "test@test.ch")
            api.perform(request: route, response: Response()) { (task, response) in
                XCTAssertEqual(response.responseCode, 1000)
                XCTAssert(response.error == nil)
                responseResult(response.responseCode == 1000)
                expectation1.fulfill()
            }
        }
        api.humanDelegate = testHumanVerifyDelegate

        let client = TestApiClient(api: api)
        client.triggerHumanVerify { (_, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testSmsMethodSuccess() {
        // backend answer when there is no verification token
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && !hasHeaderNamed("x-pm-human-verification-token")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // backend answer with verification token and verification token type
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && hasHeaderNamed("x-pm-human-verification-token", value: smsToken) && hasHeaderNamed("x-pm-human-verification-token-type", value: "sms") && hasHeaderNamed("Content-Type")) { request in
            let body = self.responseStringSuccess.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        let expectation1 = self.expectation(description: "Success send code completion block called testSmsMethodSuccess")
        let expectation2 = self.expectation(description: "Success verification completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let resultHeaders: [String: Any] = ["x-pm-human-verification-token": smsToken, "x-pm-human-verification-token-type": "sms"]
        let testHumanVerifyDelegate = HumanCheckHelperMock(apiService: api, resultSuccess: true, resultHeaders: [resultHeaders]) { responseResult in
            // api request to send verification code to the sms
            let route = UserAPI.Router.code(type: .sms, receiver: "+41000000000")
            api.perform(request: route, response: Response()) { (task, response) in
                XCTAssertEqual(response.responseCode, 1000)
                XCTAssert(response.error == nil)
                responseResult(response.responseCode == 1000)
                expectation1.fulfill()
            }
        }
        api.humanDelegate = testHumanVerifyDelegate

        let client = TestApiClient(api: api)
        client.triggerHumanVerify { (_, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 3) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

    func testHumanVerificationFailFailSuccess() {
        // Human verification request with code fail, fail and success.

        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // backend answer when there is no verification token
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && !hasHeaderNamed("x-pm-human-verification-token")) { request in
            let body = self.responseString9001.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // fail backend answer with verification token and verification token type
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && hasHeaderNamed("x-pm-human-verification-token", value: smsToken) && hasHeaderNamed("x-pm-human-verification-token-type", value: "sms") && hasHeaderNamed("Content-Type")) { request in
            let body = self.responseStringVerificationError.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        // success backend answer with verification token and verification token type
        stub(condition: isMethodPOST() && isPath("/api/internal/tests/humanverification") && hasHeaderNamed("x-pm-human-verification-token", value: emailToken) && hasHeaderNamed("x-pm-human-verification-token-type", value: "email") && hasHeaderNamed("Content-Type")) { request in
            let body = self.responseStringSuccess.data(using: String.Encoding.utf8)!
            let headers = ["Content-Type": "application/json;charset=utf-8"]
            return HTTPStubsResponse(data: body, statusCode: 200, headers: headers)
        }

        let expectation1 = self.expectation(description: "Success send code completion block called testHumanVerificationFailFailSuccess")
        let expectation2 = self.expectation(description: "Success verification completion block called")
        let api = PMAPIService.createAPIService(doh: TestDoH.default as DoHInterface, sessionUID: "testSessionUID", challengeParametersProvider: .forAPIService(clientApp: .other(named: "core"), challenge: .init()))
        let testAuthDelegate = TestAuthDelegate()
        api.authDelegate = testAuthDelegate
        let testAPIServiceDelegate = TestAPIServiceDelegate()
        api.serviceDelegate = testAPIServiceDelegate

        let resultHeadersSmsFail: [String: Any] = ["x-pm-human-verification-token": smsToken, "x-pm-human-verification-token-type": "sms"]
        let resultHeadersEmailSuccess: [String: Any] = ["x-pm-human-verification-token": emailToken, "x-pm-human-verification-token-type": "email"]
        let testHumanVerifyDelegate = HumanCheckHelperMock(apiService: api, resultSuccess: true, resultHeaders: [resultHeadersSmsFail, resultHeadersSmsFail, resultHeadersEmailSuccess], delay: 0.1) { responseResult in
            // api request to send verification code to the sms
            let route = UserAPI.Router.code(type: .sms, receiver: "+41000000000")
            api.perform(request: route, response: Response()) { (task, response) in
                XCTAssertEqual(response.responseCode, 1000)
                XCTAssert(response.error == nil)
                responseResult(response.responseCode == 1000)
                expectation1.fulfill()
            }
        }

        api.humanDelegate = testHumanVerifyDelegate

        let client = TestApiClient(api: api)
        client.triggerHumanVerify { (_, response) in
            XCTAssertEqual(response.responseCode, 1000)
            XCTAssert(response.error == nil)
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 50) { (expectationError) -> Void in
            XCTAssertNil(expectationError)
        }
    }

}

#endif
