//
//  PaymentsUIViewModelMock.swift
//  ProtonCore-PaymentsUI-Tests - Created on 13/09/2023.
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

import Foundation
import ProtonCorePayments
@testable import ProtonCorePaymentsUI
import ProtonCoreTestingToolkitUnitTestsPayments

class PaymentsUIViewModelMock: PaymentsUIViewModel {
    let fetchPlansHandler: () -> Void
    init(fetchPlansHandler: @escaping () -> Void) {
        self.fetchPlansHandler = fetchPlansHandler
        super.init(
            mode: .current,
            storeKitManager: StoreKitManagerMock(),
            planService: .left(ServicePlanDataServiceMock()),
            clientApp: .vpn,
            customPlansDescription: [:],
            planRefreshHandler: { _ in },
            extendSubscriptionHandler: { }
        )
    }
    override func fetchPlans() async throws {
        fetchPlansHandler()
    }
}

#endif
