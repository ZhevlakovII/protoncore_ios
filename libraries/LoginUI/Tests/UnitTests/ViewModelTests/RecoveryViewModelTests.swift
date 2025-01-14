//
//  RecoveryViewModelTests.swift
//  ProtonCore-Login-Tests - Created on 09.04.21.
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

import ProtonCoreChallenge
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUnitTestsLogin
import ProtonCoreTestingToolkitUnitTestsServices
#elseif canImport(ProtonCoreTestingToolkit)
import ProtonCoreTestingToolkit
#endif
import ProtonCoreCryptoGoInterface
#if canImport(ProtonCoreCryptoPatchedGoImplementation)
import ProtonCoreCryptoPatchedGoImplementation
#elseif canImport(ProtonCoreCryptoGoImplementation)
import ProtonCoreCryptoGoImplementation
#elseif canImport(ProtonCoreCryptoSearchGoImplementation)
import ProtonCoreCryptoSearchGoImplementation
#elseif canImport(ProtonCoreCryptoVPNPatchedGoImplementation)
import ProtonCoreCryptoVPNPatchedGoImplementation
#endif
@testable import ProtonCoreLoginUI

class RecoveryViewModelTests: XCTestCase {

    var signupServiceMock: SignupServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        injectDefaultCryptoImplementation()
        signupServiceMock = SignupServiceMock()
    }

    func testPhoneNumberValidation() throws {
        let viewModel = RecoveryViewModel(signupService: signupServiceMock, initialCountryCode: 0, challenge: PMChallenge())
        XCTAssertEqual(viewModel.isValidPhoneNumber(number: ""), false)
        XCTAssertEqual(viewModel.isValidPhoneNumber(number: "0"), true)
        XCTAssertEqual(viewModel.isValidPhoneNumber(number: "+41111111"), true)
        XCTAssertEqual(viewModel.isValidPhoneNumber(number: "123"), true)
    }

    func testEmailValidationFail() throws {
        let viewModel = RecoveryViewModel(signupService: signupServiceMock, initialCountryCode: 0, challenge: PMChallenge())
        XCTAssertEqual(viewModel.isValidEmail(email: ""), false)
        XCTAssertEqual(viewModel.isValidEmail(email: "123"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: "1111@"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: "sadsds@kjdk"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: "aaa.ch"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: ".ch"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: "jahja/aa"), false)
        XCTAssertEqual(viewModel.isValidEmail(email: ".test@test.ch"), false)
    }

    func testEmailValidationSuccess() throws {
        let viewModel = RecoveryViewModel(signupService: signupServiceMock, initialCountryCode: 0, challenge: PMChallenge())
        XCTAssertEqual(viewModel.isValidEmail(email: "test@test.ch"), true)
        XCTAssertEqual(viewModel.isValidEmail(email: "test@test.x"), true)
        XCTAssertEqual(viewModel.isValidEmail(email: "aasa.aaa-x@x.x"), true)
    }
}

#endif
