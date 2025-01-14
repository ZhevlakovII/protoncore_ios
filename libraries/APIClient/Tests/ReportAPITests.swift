//
//  ReportAPITests.swift
//  ProtonCore-APIClient-Tests - Created on 08/31/2021.
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

#if canImport(ProtonCoreTestingToolkitUnitTestsAuthentication)
import ProtonCoreTestingToolkitUnitTestsAuthentication
import ProtonCoreTestingToolkitUnitTestsServices
#else
import ProtonCoreTestingToolkit
#endif
import ProtonCoreDoh
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreAuthentication

@testable import ProtonCoreAPIClient

class ReportAPITests: XCTestCase {

    var authenticatorMock: AuthenticatorMock!
    var apiService: APIServiceMock!
    let timeout = 1.0

    private var testBundle: Bundle!

    let testCredential = Credential(UID: "testUID", accessToken: "testAccessToken", refreshToken: "testRefreshToken", userName: "testUserName", userID: "testUserID", scopes: ["testScope"])

    let bug = ReportBug.init(os: "Mac OS", osVersion: "10.15.7",
                             client: "Web Mail", clientVersion: "iOS_1.12.0",
                             clientType: 1, title: "[V4] [Web Mail] Bug [/archive] Sign up problem",
                             description: "ignore this . test from feng", username: "feng100",
                             email: "email@example.com", country: "US", ISP: "test", plan: "free")

    func content(of name: String, ext: String) -> String {
        let url = testBundle.url(forResource: name, withExtension: ext)!
        let content = try! String.init(contentsOf: url)
        return content
    }

    override func setUp() {
        super.setUp()
        authenticatorMock = AuthenticatorMock()
        apiService = APIServiceMock()
        self.testBundle = Bundle.module
    }

    func testUploadAndProgressSuccess() {
        authenticatorMock.authenticateStub.bodyIs { _, _, _, _, _, _, completion  in
            completion(.success(.newCredential(self.testCredential, .one)))
        }
        apiService.uploadFilesDecodableStub.bodyIs { _, path, _, _, _, _, _, _, _, progress, completion in
            progress?(Progress())
            if path.contains("/core/v4/reports/bug") {
                let response = ReportsBugsResponse(code: 1000)
                completion(nil, .success(response))
            } else {
                XCTFail()
                completion(nil, .success([:]))
            }
        }

        let url = testBundle.url(forResource: "my_dogs", withExtension: "jpg")!
        let files: [String: URL] = ["my_dogs": url]
        let expect1 = expectation(description: "AuthInfo + Auth")
        let expect2 = expectation(description: "Progress is called")
        authenticatorMock.authenticate(username: "username", password: "password", challenge: nil, intent: nil, srpAuth: nil) { result in
            switch result {
            case .success(Authenticator.Status.newCredential(let firstCredential, _)):
                let authCredential = AuthCredential(firstCredential)
                let route = ReportsBugs(self.bug)
                route.auth = authCredential
                self.apiService.performUpload(request: route, files: files, uploadProgress: { progress in expect2.fulfill() },
                                              decodableCompletion: { (_, result: Result<ReportsBugsResponse, ResponseError>) in
                    switch result {
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                        expect1.fulfill()
                    case .success(let response):
                        XCTAssertTrue(response.code == 1000)
                        expect1.fulfill()
                    }
                })
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expect1.fulfill()
            default:
                XCTFail("Auth flow failed")
                expect1.fulfill()
            }
        }
        let result = XCTWaiter.wait(for: [expect1, expect2], timeout: timeout)
        XCTAssertTrue(result == .completed)
    }

    func testUploadAndProgressNetworkingError() {
        authenticatorMock.authenticateStub.bodyIs { _, _, _, _, _, _, completion in
            completion(.success(.newCredential(self.testCredential, .one)))
        }
        let testResponseError = ResponseError(httpCode: 400, responseCode: 404, userFacingMessage: "testError", underlyingError: nil)
        apiService.uploadFilesDecodableStub.bodyIs { _, path, _, _, _, _, _, _, _, progress, completion in
            progress?(Progress())
            completion(nil, .failure(testResponseError as NSError))
        }

        let url = testBundle.url(forResource: "my_dogs", withExtension: "jpg")!
        let files: [String: URL] = ["my_dogs": url]
        let expect1 = expectation(description: "AuthInfo + Auth")
        let expect2 = expectation(description: "Progress is called")
        authenticatorMock.authenticate(username: "username", password: "password", challenge: nil, intent: nil, srpAuth: nil) { result in
            switch result {
            case .success(Authenticator.Status.newCredential(let firstCredential, _)):
                let authCredential = AuthCredential(firstCredential)
                let route = ReportsBugs(self.bug)
                route.auth = authCredential
                self.apiService.performUpload(request: route, files: files, uploadProgress: { progress in
                    expect2.fulfill()
                }, decodableCompletion: { (_, result: Result<ReportsBugsResponse, ResponseError>) in
                    switch result {
                    case .failure(let responseError):
                        XCTAssertEqual(responseError, testResponseError)
                        expect1.fulfill()
                    case .success:
                        XCTFail()
                        expect1.fulfill()
                    }
                })
            case .failure(let error):
                XCTFail(error.localizedDescription)
                expect1.fulfill()
            default:
                XCTFail("Auth flow failed")
                expect1.fulfill()
            }
        }
        let result = XCTWaiter.wait(for: [expect1, expect2], timeout: timeout)
        XCTAssertTrue(result == .completed)
    }
}
