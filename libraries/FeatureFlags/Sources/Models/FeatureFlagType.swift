//
//  FeatureFlagType.swift
//  ProtonCore-FeatureFlags - Created on 29.09.23.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//

public enum CoreFeatureFlagType: String, FeatureFlagTypeProtocol {
    case accountRecovery = "SignedInAccountRecovery"
    case changePassword = "IOSChangePassword"
    case dynamicPlan = "DynamicPlan"
    case fidoKeys = "FIDO2Mobile"
    case pushNotifications = "PushNotifications"
    case reportInvalidUnauthRequests = "ReportInvalidUnauthRequests"
    case splitStorage = "SplitStorage"
    case telemetrySignUpMetrics = "IOSTelemetrySignUpMetrics"
    case globalSSODisabled = "GlobalSSODisabled"
}
