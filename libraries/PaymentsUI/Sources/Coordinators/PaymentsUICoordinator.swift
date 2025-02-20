//
//  PaymentsUICoordinator.swift
//  ProtonCorePaymentsUI - Created on 01/06/2021.
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

import enum ProtonCoreDataModel.ClientApp
import ProtonCoreFeatureFlags
import ProtonCoreFoundations
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCorePayments
import ProtonCoreUIFoundations
import ProtonCoreUtilities
import UIKit

final class PaymentsUICoordinator {
    private var viewController: UIViewController?
    private var presentationType: PaymentsUIPresentationType = .modal
    private var mode: PaymentsUIMode = .signup
    private var completionHandler: ((PaymentsUIResultReason) -> Void)?
    var viewModel: PaymentsUIViewModel?
    private var onDohTroubleshooting: () -> Void

    private let planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>
    private let storeKitManager: StoreKitManagerProtocol
    private let purchaseManager: PurchaseManagerProtocol
    private let shownPlanNames: ListOfShownPlanNames
    private let customization: PaymentsUICustomizationOptions
    private let alertManager: PaymentsUIAlertManager
    private let clientApp: ClientApp
    private let storyboardName: String
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol
    private var unfinishedPurchasePlan: InAppPurchasePlan? {
        didSet {
            guard let unfinishedPurchasePlan = unfinishedPurchasePlan else { return }
            viewModel?.unfinishedPurchasePlan = unfinishedPurchasePlan
        }
    }

    var paymentsUIViewController: PaymentsUIViewController? {
        didSet { alertManager.viewController = paymentsUIViewController }
    }

    init(planService: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>,
         storeKitManager: StoreKitManagerProtocol,
         purchaseManager: PurchaseManagerProtocol,
         clientApp: ClientApp,
         shownPlanNames: ListOfShownPlanNames,
         customization: PaymentsUICustomizationOptions,
         alertManager: PaymentsUIAlertManager,
         onDohTroubleshooting: @escaping () -> Void,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol = FeatureFlagsRepository.shared)
    {
        self.planService = planService
        self.storeKitManager = storeKitManager
        self.purchaseManager = purchaseManager
        self.shownPlanNames = shownPlanNames
        self.alertManager = alertManager
        self.clientApp = clientApp
        self.customization = customization
        self.storyboardName = "PaymentsUI"
        self.onDohTroubleshooting = onDohTroubleshooting
        self.featureFlagsRepository = featureFlagsRepository
    }

    func start(viewController: UIViewController?, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.viewController = viewController
        self.mode = .signup
        self.completionHandler = completionHandler
        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            Task {
                await showPaymentsUI(servicePlan: planService)
            }
        } else {
            showPaymentsUI(servicePlan: planService, backendFetch: false)
        }
    }

    func start(presentationType: PaymentsUIPresentationType, mode: PaymentsUIMode, backendFetch: Bool, completionHandler: @escaping ((PaymentsUIResultReason) -> Void)) {
        self.presentationType = presentationType
        self.mode = mode
        self.completionHandler = completionHandler
        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            Task {
                await showPaymentsUI(servicePlan: planService)
            }
        } else {
            showPaymentsUI(servicePlan: planService, backendFetch: backendFetch)
        }
    }

    // MARK: Private methods

    private func showPaymentsUI(servicePlan _: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>) async {
        let paymentsUIViewController = await MainActor.run {
            let paymentsUIViewController = UIStoryboard.instantiate(
                PaymentsUIViewController.self, storyboardName: storyboardName, inAppTheme: customization.inAppTheme
            )
            paymentsUIViewController.delegate = self
            paymentsUIViewController.onDohTroubleshooting = { [weak self] in
                self?.onDohTroubleshooting()
            }
            return paymentsUIViewController
        }

        viewModel = PaymentsUIViewModel(
            mode: mode,
            storeKitManager: storeKitManager,
            planService: planService,
            shownPlanNames: shownPlanNames,
            clientApp: clientApp,
            customPlansDescription: customization.customPlansDescription,
            planRefreshHandler: { [weak self] updatedPlan in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.paymentsUIViewController?.reloadData()
                        if updatedPlan != nil {
                            self?.paymentsUIViewController?.showPurchaseSuccessBanner()
                        }
                    }
                }
            },
            extendSubscriptionHandler: { [weak self] in
                Task { [weak self] in
                    await MainActor.run { [weak self] in
                        self?.paymentsUIViewController?.extendSubscriptionSelection()
                    }
                }
            }
        )

        await MainActor.run {
            self.paymentsUIViewController = paymentsUIViewController
            paymentsUIViewController.viewModel = viewModel
            paymentsUIViewController.mode = mode

            if mode != .signup {
                showPlanViewController(paymentsViewController: paymentsUIViewController)
            }
        }

        do {
            try await viewModel?.fetchPlans()
            unfinishedPurchasePlan = purchaseManager.unfinishedPurchasePlan
            await MainActor.run {
                if mode == .signup {
                    showPlanViewController(paymentsViewController: paymentsUIViewController)
                } else {
                    paymentsUIViewController.reloadData()
                }
            }
        } catch {
            await MainActor.run {
                showError(error: error)
            }
            PMLog.error("Could not fetch plans \(error)", sendToExternal: true)
        }
    }

    private func showPaymentsUI(servicePlan _: Either<ServicePlanDataServiceProtocol, PlansDataSourceProtocol>, backendFetch: Bool) {
        let paymentsUIViewController = UIStoryboard.instantiate(
            PaymentsUIViewController.self, storyboardName: storyboardName, inAppTheme: customization.inAppTheme
        )
        paymentsUIViewController.delegate = self
        paymentsUIViewController.onDohTroubleshooting = { [weak self] in
            self?.onDohTroubleshooting()
        }

        viewModel = PaymentsUIViewModel(mode: mode,
                                        storeKitManager: storeKitManager,
                                        planService: planService,
                                        shownPlanNames: shownPlanNames,
                                        clientApp: clientApp,
                                        customPlansDescription: customization.customPlansDescription)
        { [weak self] updatedPlan in
            DispatchQueue.main.async { [weak self] in
                self?.paymentsUIViewController?.reloadData()
                if updatedPlan != nil {
                    self?.paymentsUIViewController?.showPurchaseSuccessBanner()
                }
            }
        } extendSubscriptionHandler: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.paymentsUIViewController?.extendSubscriptionSelection()
            }
        }
        self.paymentsUIViewController = paymentsUIViewController
        paymentsUIViewController.viewModel = viewModel
        paymentsUIViewController.mode = mode
        if mode != .signup {
            showPlanViewController(paymentsViewController: paymentsUIViewController)
        }

        viewModel?.fetchPlans(backendFetch: backendFetch) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                if self.mode == .signup {
                    self.showPlanViewController(paymentsViewController: paymentsUIViewController)
                } else {
                    paymentsUIViewController.reloadData()
                }
            case let .failure(error):
                DispatchQueue.main.async { [weak self] in
                    self?.showError(error: error)
                }
                PMLog.error("Could not fetch plans \(error)", sendToExternal: true)
            }
        }
    }

    private func showPlanViewController(paymentsViewController: PaymentsUIViewController) {
        if mode == .signup {
            viewController?.navigationController?.pushViewController(paymentsViewController, animated: true)
            completionHandler?(.open(vc: paymentsViewController, opened: true))
            if unfinishedPurchasePlan != nil {
                showProcessingTransactionAlert()
            }
        } else {
            switch presentationType {
            case .modal:
                var topViewController: UIViewController?
                let keyWindow = UIApplication.firstKeyWindow
                if var top = keyWindow?.rootViewController {
                    while let presentedViewController = top.presentedViewController {
                        top = presentedViewController
                    }
                    topViewController = top
                }
                paymentsViewController.modalPresentation = true
                let navigationController = LoginNavigationViewController(rootViewController: paymentsViewController)
                navigationController.overrideUserInterfaceStyle = customization.inAppTheme().userInterfaceStyle
                navigationController.modalPresentationStyle = .pageSheet
                topViewController?.present(navigationController, animated: true)
                completionHandler?(.open(vc: paymentsViewController, opened: true))
            case .none:
                paymentsViewController.modalPresentation = false
                completionHandler?(.open(vc: paymentsViewController, opened: false))
            }
        }
    }

    private func showError(error: Error) {
        if let error = error as? StoreKitManagerErrors {
            showError(message: error.userFacingMessageInPayments, error: error)
        } else if let error = error as? ResponseError {
            showError(message: error.localizedDescription, error: error)
        } else if let error = error as? AuthErrors, error.isInvalidAccessToken {
            // silence invalid access token error
        } else {
            showError(message: error.userFacingMessageInPayments, error: error)
        }
        finishCallback(reason: .purchaseError(error: error))
    }

    private func showError(message: String, error: Error, action: ActionCallback = nil) {
        guard localErrorMessages else { return }
        alertManager.showError(message: message, error: error, action: action)
    }

    private var localErrorMessages: Bool {
        return mode != .signup
    }

    private func finishCallback(reason: PaymentsUIResultReason) {
        completionHandler?(reason)
    }

    private func showProcessingTransactionAlert(isError: Bool = false) {
        guard unfinishedPurchasePlan != nil else { return }

        let title = isError ? PUITranslations.plan_unfinished_error_title.l10n : PUITranslations._payments_warning.l10n
        let message = isError ? PUITranslations.plan_unfinished_error_desc.l10n : PUITranslations.plan_unfinished_desc.l10n
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: isError ? PUITranslations.plan_unfinished_error_retry_button.l10n : PSTranslation._core_retry.l10n, style: .default, handler: { _ in

            // unregister from being notified on the transactions — we're finishing immediately
            guard let unfinishedPurchasePlan = self.unfinishedPurchasePlan else { return }
            self.storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()
            self.finishCallback(reason: .purchasedPlan(accountPlan: unfinishedPurchasePlan))
        })
        retryAction.accessibilityLabel = "DialogRetryButton"
        alertController.addAction(retryAction)
        let cancelAction = UIAlertAction(title: PUITranslations._core_cancel_button.l10n, style: .default) { _ in
            // close Payments UI
            self.completionHandler?(.close)
        }
        cancelAction.accessibilityLabel = "DialogCancelButton"
        alertController.addAction(cancelAction)
        paymentsUIViewController?.present(alertController, animated: true, completion: nil)
    }

    private func refreshPlans() async {
        do {
            try await viewModel?.fetchPlans()
            Task { @MainActor in
                paymentsUIViewController?.reloadData()
            }
        } catch {
            PMLog.info("Failed to fetch plans when PaymentsUIViewController will appear: \(error)")
        }
    }
}

// MARK: PaymentsUIViewControllerDelegate

extension PaymentsUICoordinator: PaymentsUIViewControllerDelegate {
    func viewControllerWillAppear(isFirstAppearance: Bool) {
        // Plan data should not be refreshed on first appear because at that time data are freshly loaded. Here must be covered situations when
        // app goes from background for example.
        guard !isFirstAppearance else { return }
        if featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            Task {
                await refreshPlans()
            }
        }
    }

    func userDidCloseViewController() {
        if presentationType == .modal, mode != .signup {
            paymentsUIViewController?.dismiss(animated: true, completion: nil)
        } else {
            paymentsUIViewController?.navigationController?.popViewController(animated: true)
        }
        completionHandler?(.close)
    }

    func userDidDismissViewController() {
        completionHandler?(.close)
    }

    func userDidSelectPlan(plan: AvailablePlansPresentation, completionHandler: @escaping () -> Void) {
        guard let inAppPlan = plan.availablePlan else {
            completionHandler()
            return
        }
        userDidSelectPlan(plan: inAppPlan, addCredits: false, completionHandler: completionHandler)
    }

    func userDidSelectPlan(plan: PlanPresentation, addCredits: Bool, completionHandler: @escaping () -> Void) {
        userDidSelectPlan(plan: plan.accountPlan, addCredits: false, completionHandler: completionHandler)
    }

    private func userDidSelectPlan(plan: InAppPurchasePlan, addCredits: Bool, completionHandler: @escaping () -> Void) {
        // unregister from being notified on the transactions — you will get notified via `buyPlan` completion block
        storeKitManager.stopBeingNotifiedWhenTransactionsWaitingForTheSignupAppear()

        purchaseManager.buyPlan(plan: plan, addCredits: addCredits) { [weak self] purchaseResult in
            guard let self = self else { return }

            reportObservability(plan: plan, result: purchaseResult)

            switch purchaseResult {
            case let .planPurchaseProcessingInProgress(inProgressPlan):
                self.unfinishedPurchasePlan = inProgressPlan
                self.finishCallback(reason: .planPurchaseProcessingInProgress(accountPlan: inProgressPlan))

            case let .purchasedPlan(purchasedPlan):
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                self.finishCallback(reason: .purchasedPlan(accountPlan: purchasedPlan))

            case .toppedUpCredits:
                self.unfinishedPurchasePlan = self.purchaseManager.unfinishedPurchasePlan
                self.finishCallback(reason: .toppedUpCredits)

            case let .purchaseError(error, processingPlan):
                self.unfinishedPurchasePlan = processingPlan
                self.finishCallback(reason: .purchaseError(error: error))
                self.showError(error: error)

            case let .apiMightBeBlocked(message, originalError, processingPlan):
                self.unfinishedPurchasePlan = processingPlan
                self.finishCallback(reason: .apiMightBeBlocked(message: message, originalError: originalError))

            case .purchaseCancelled:
                // No callback called, we remain in the subscriptions screen
                break
            case .renewalNotification:
                break // precondition prevents it
            }

            completionHandler()
        }
    }

    func getPlanNameForObservabilityPurposes(plan: InAppPurchasePlan) -> PlanName {
        if plan.protonName == InAppPurchasePlan.freePlanName || plan.protonName.contains("free") {
            return .free
        } else {
            return .paid
        }
    }

    func planPurchaseError() {
        if mode == .signup {
            showProcessingTransactionAlert(isError: true)
        }
    }

    func purchaseBecameUnavailable() {
        showError(message: PUITranslations.iap_temporarily_unavailable.l10n,
                  error: PlansDataSourceError.purchaseBecameUnavailable)
        {
            self.userDidCloseViewController()
        }
    }

    private func reportObservability(plan: InAppPurchasePlan, result: PurchaseResult) {
        let isDynamic = featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan)

        ObservabilityEnv.report(.paymentLaunchBillingTotal(status: result.launchBillingStatus, isDynamic: isDynamic))
        ObservabilityEnv.report(.paymentPurchaseTotal(status: result.purchaseStatus, isDynamic: isDynamic))
        ObservabilityEnv.report(.planSelectionCheckoutTotal(status: result.planSelectionCheckoutStatus, plan: getPlanNameForObservabilityPurposes(plan: plan), isDynamic: isDynamic))
    }
}

private extension UIStoryboard {
    static func instantiate<T: UIViewController>(
        _ controllerType: T.Type, storyboardName: String, inAppTheme: () -> InAppTheme
    ) -> T {
        instantiate(storyboardName: storyboardName, controllerType: controllerType, inAppTheme: inAppTheme)
    }
}

#endif
