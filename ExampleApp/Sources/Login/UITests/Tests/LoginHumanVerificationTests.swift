//
//  LoginHumanVerificationTests.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-04-23.
//

import XCTest
import fusion
#if canImport(ProtonCoreTestingToolkitUITestsCore)
import ProtonCoreTestingToolkitUITestsCore
import ProtonCoreTestingToolkitUITestsHumanVerification
import ProtonCoreTestingToolkitUITestsLogin
#else
import ProtonCoreTestingToolkit
#endif
import ProtonCoreObfuscatedConstants
import ProtonCoreQuarkCommands

class LoginHumanVerificationTests: LoginBaseTestCase {

    let mainRobot = LoginSampleAppRobot()
    let loginRobot = LoginRobot()
    let twoFaRobot = TwoFaRobot()
    let needHelpRobot = NeedHelpRobot()
    let createProtonmailRobot = CreateProtonmailRobot()

    let password = ObfuscatedConstants.password
    let emailVerificationCode = ObfuscatedConstants.emailVerificationCode

    override func setUp() {
        beforeSetUp(launchArguments: ["UITests_MockHVInAuth"])

        super.setUp()
        mainRobot
            .changeEnvironmentToCustomIfDomainHereBlackOtherwise(dynamicDomainAvailable)
            .humanVerificationSwitchTap()
    }

    func testHumanVerificationIsHandledInLogin() {
        let user = testData.onePassUser
        mainRobot
            .showLogin()
            .fillUsername(username: user.username)
            .fillpassword(password: user.password)
            .signIn(robot: HumanVerificationRobot.self)
            .captchaTap(captcha: .hCaptcha, to: LoginSampleAppRobot.self)
            .verify.buttonLogoutVisible()
    }
}
