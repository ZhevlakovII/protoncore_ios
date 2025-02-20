//
//  ExampleViewController.swift
//  CoreExample - Created on 06/10/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit

import ProtonCoreAuthentication
import ProtonCoreDoh
import ProtonCoreLog
import ProtonCoreFoundations
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonCoreLogin
import ProtonCoreTroubleShooting
import ProtonCoreEnvironment
import ProtonCoreObfuscatedConstants

final class ExampleViewController: UIViewController, AccessibleView {

    @IBOutlet var targetLabel: UILabel!

    @IBOutlet var accountDeletionButton: UIButton!
    @IBOutlet var accountSwitcherButton: UIButton!
    @IBOutlet var featuresButton: UIButton!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var networkingButton: UIButton!
    @IBOutlet var paymentsButton: UIButton!
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var tokenRefreshButton: UIButton!
    @IBOutlet var uiFoundationButton: UIButton!
    @IBOutlet var appVersionTextField: UITextField!
    @IBOutlet var alternativeRoutingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var trustKitSegmentedControl: UISegmentedControl!
    @IBOutlet var scenarioPicker: UIPickerView!
    @IBOutlet var scenarioButton: UIButton!
    @IBOutlet var appVersionResetButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        ColorProvider.brand = clientApp == .vpn ? .vpn : .proton

        /// Move this to Core
        PMAPIService.trustKit = Environment.setUpTrustKit(delegate: self)
        PMAPIService.noTrustKit = true

        appVersionTextField.delegate = self
        appVersionTextField.placeholder = appVersionHeader.getDefaultVersion()
        updateAppVersion()

        targetLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        setupAlertControllerAppearance()
        generateAccessibilityIdentifiers()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if clientApp == .vpn {
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ColorProvider.brand = clientApp == .vpn ? .vpn : .proton
    }

    @IBAction private func alternativeRoutingSetupChanged(_ sender: Any?) {
        dismissKeyboard()
        switch alternativeRoutingSegmentedControl.selectedSegmentIndex {
        case 0:
            Environment.prebuild.forEach { env in
                env.updateDohStatus(to: .off)
            }
        case 1:
            Environment.prebuild.forEach { env in
                env.updateDohStatus(to: .on)
            }
        case 2:
            Environment.prebuild.forEach { env in
                env.updateDohStatus(to: .forceAlternativeRouting)
            }
            [Environment.mailProd, Environment.vpnProd, Environment.driveProd, Environment.calendarProd].forEach { (env: Environment) in
                ProductionHosts.allCases.forEach { host in
                    env.doh.handleErrorResolvingProxyDomainIfNeeded(
                        host: host.urlString, requestHeaders: [DoHConstants.dohHostHeader: host.rawValue],
                        sessionId: nil, error: nil, completion: { _ in }
                    )
                }
            }
            PMLog.debug("Switched to forced alternative routing")
        default: return
        }
    }

    @IBAction func trustKitSetupChanged(_ sender: UISegmentedControl) {
        dismissKeyboard()
        switch trustKitSegmentedControl.selectedSegmentIndex {
        case 0: PMAPIService.noTrustKit = true
        case 1: PMAPIService.noTrustKit = false
        default: return
        }
    }

    @IBAction func appVersionEditingChanged(_ sender: UITextField) {
        appVersionHeader.setVersion(version: sender.text)
    }

    @IBAction func appVersionResetTap(_ sender: UIButton) {
        dismissKeyboard()
        appVersionHeader.resetVersion()
        updateAppVersion()
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }

    @IBAction func testPMLogSentry(_ sender: Any) {
        PMLog.error("This is a test from ExampleApp", sendToExternal: true)
    }

    private func dismissKeyboard() {
        _ = appVersionTextField.resignFirstResponder()
    }

    private func updateAppVersion() {
        appVersionTextField.text = appVersionHeader.getVersion()
    }

    let authManager = AuthHelper()

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LoginViewController {
            vc.authManager = authManager
        }
    }

    private func setupAlertControllerAppearance() {
        let view = UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
        view.tintColor = ColorProvider.BrandNorm
    }
}

extension ExampleViewController: TrustKitDelegate {
    func onTrustKitValidationError(_ error: TrustKitError) {

    }
}

extension ExampleViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }
}
