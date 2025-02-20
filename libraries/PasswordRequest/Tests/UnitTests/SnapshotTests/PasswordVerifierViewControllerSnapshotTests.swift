//
//  PasswordVerifierViewControllerSnapshotTests.swift
//  ProtonCore-PasswordRequest-Unit-Tests - Created on 14.07.23.
//
//  Copyright (c) 2023 Proton AG
//
//  This file is part of ProtonCore.
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
@testable import ProtonCorePasswordRequest

#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUnitTestsServices
#else
import ProtonCoreTestingToolkit
#endif

@available(iOS 13, *)
final class PasswordVerifierViewControllerSnapshotTests: SnapshotTestCase {

    let defaultPrecision: Float = 0.98

    func testPasswordVerifierView() {
        let controller = PasswordVerifierViewController()
        checkSnapshots(controller: controller, perceptualPrecision: defaultPrecision)
    }

    func testPasswordVerifierView_forAccountRecovery() {
        let controller = PasswordVerifierViewController()
        controller.viewModel = .init(apiService: APIServiceMock(), username: "", endpoint: UnlockEndpoint(), missingScopeMode: .accountRecovery)
        checkSnapshots(controller: controller, perceptualPrecision: defaultPrecision)
    }
}

#endif
