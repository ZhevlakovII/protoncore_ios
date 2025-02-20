//
//  LoginSSOSnapshotTests.swift
//  ProtonCore-LoginUI-Unit-TestsUsingCrypto - Created on 23/08/2024.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.

#if os(iOS)

import XCTest
@testable import ProtonCoreLoginUI
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#endif

class LoginSSOSnapshotTests: SnapshotTestCase {

    let defaultPrecision: Float = 0.98

    @MainActor
    func testJoinOrganizationView() {
        let viewController = JoinOrganizationViewController()

        checkSnapshots(controller: viewController, perceptualPrecision: defaultPrecision)
    }

    @MainActor
    func testSignInRequestViewModeRequestForAdminApproval() {
        let viewController = SignInRequestViewController(mode: .requestForAdminApproval(code: "64S3"))

        checkSnapshots(controller: viewController, perceptualPrecision: defaultPrecision)
    }

    @MainActor
    func testSignInRequestViewModeRequestApproveFromAnotherDevice() {
        let viewController = SignInRequestViewController(mode: .requestApproveFromAnotherDevice(code: "64S3"))

        checkSnapshots(controller: viewController, perceptualPrecision: defaultPrecision)
    }

    @MainActor
    func testSignInRequestViewModeApprovingAccess() {
        let viewController = SignInRequestViewController(mode: .approvingAccess)

        checkSnapshots(controller: viewController, perceptualPrecision: defaultPrecision)
    }
}

#endif
