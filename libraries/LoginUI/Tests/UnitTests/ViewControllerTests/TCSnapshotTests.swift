//
//  TCSnapshotTests.swift
//  ProtonCore-LoginUI-Unit-Tests-Crypto-Go1.19.2 - Created on 06.01.23.
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
//  along with ProtonCore. If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import XCTest
#if canImport(ProtonCoreTestingToolkitUnitTestsCore)
import ProtonCoreTestingToolkitUnitTestsCore
#elseif canImport(ProtonCoreTestingToolkit)
import ProtonCoreTestingToolkit
#endif
import ProtonCoreUIFoundations
@testable import ProtonCoreLoginUI

@available(iOS 13, *)
class TCSnapshotTests: SnapshotTestCase {

    func testTCViewControllerScreen() {
        let elViewController = UIStoryboard.instantiate(storyboardName: "PMSignup", controllerType: ExternalLinkViewController.self, inAppTheme: { .default })
        elViewController.configuration = .init(title: LUITranslation.terms_conditions_view_title.l10n, url: URL(string: "https://proton.me")!)
        let navigationViewController = LoginNavigationViewController(rootViewController: elViewController)
        checkSnapshots(controller: navigationViewController, perceptualPrecision: 0.98)
    }
}

#endif
