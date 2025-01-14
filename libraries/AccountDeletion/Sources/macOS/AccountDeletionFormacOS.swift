//
//  AccountDeletionWebView.swift
//  ProtonCore-AccountDeletion - Created on 10.12.21.
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

#if os(macOS)

import AppKit
import ProtonCoreNetworking
import ProtonCoreUIFoundations

public typealias AccountDeletionViewController = NSViewController

public protocol AccountDeletionViewControllerPresenter {
    func presentAsModalWindow(_: NSViewController)
}

extension NSViewController: AccountDeletionViewControllerPresenter {}

extension AccountDeletionService: AccountDeletion {

    public func initiateAccountDeletionProcess(
        over viewController: NSViewController,
        inAppTheme: @escaping () -> InAppTheme = { .default },
        performAfterShowingAccountDeletionScreen: @escaping () -> Void = { },
        performBeforeClosingAccountDeletionScreen: @escaping (@escaping () -> Void) -> Void = { $0() },
        completion: @escaping (Result<AccountDeletionSuccess, AccountDeletionError>) -> Void
    ) {
        initiateAccountDeletionProcess(presenter: viewController,
                                       inAppTheme: inAppTheme,
                                       performAfterShowingAccountDeletionScreen: performAfterShowingAccountDeletionScreen,
                                       performBeforeClosingAccountDeletionScreen: performBeforeClosingAccountDeletionScreen,
                                       completion: completion)
    }
}

extension AccountDeletionWebView {

    override func loadView() {
        view = NSView(frame: NSRect(x: 0.0, y: 0.0, width: 600.0, height: 800.0))
        view.window?.styleMask = [.closable, .titled, .resizable]
        view.window?.minSize = NSSize(width: 600, height: 800)
        view.window?.maxSize = NSSize(width: 1000, height: 1000)
    }

    func styleUI() {

    }

    func presentSuccessfulLoading() {
        webView?.animator().alphaValue = 0
        webView?.isHidden = false
        loader.isHidden = true
        loader.stopAnimation(nil)

        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = 1
            self?.webView?.animator().alphaValue = 1
        }
    }

    func presentSuccessfulAccountDeletion() {
        NSAnimationContext.runAnimationGroup { [weak self] context in
            context.duration = 1
            self?.webView?.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.webView?.isHidden = true
        }

        // TODO: consult the macOS success presentation with designers
        let alert = NSAlert()
        alert.messageText = ADTranslation.delete_account_success.l10n
        alert.alertStyle = .informational
        alert.runModal()
    }

    func presentNotification(type: NotificationType, message: String) {
        // TODO: consult the macOS notification presentation with designers
        let alert = NSAlert()
        alert.messageText = message
        switch type {
        case .error: alert.alertStyle = .critical
        case .warning: alert.alertStyle = .warning
        case .info: alert.alertStyle = .informational
        case .success: alert.alertStyle = .informational
        }
        alert.runModal()
    }

    func openUrl(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

extension AccountDeletionWebView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        viewModel.deleteAccountWasClosed()
    }
}

extension AccountDeletionService: AccountDeletionWebViewDelegate {

    public func shouldCloseWebView(_ viewController: AccountDeletionViewController, completion: @escaping () -> Void) {
        viewController.presentingViewController?.dismiss(viewController)
        completion()
    }

    func present(vc: AccountDeletionWebView,
                 over: AccountDeletionViewControllerPresenter,
                 inAppTheme: @escaping () -> InAppTheme,
                 completion: @escaping () -> Void) {
        vc.title = ADTranslation.delete_account_title.l10n
        over.presentAsModalWindow(vc)
        completion()
    }
}

#endif
