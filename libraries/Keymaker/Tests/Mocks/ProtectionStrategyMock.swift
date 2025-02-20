//
//  ProtectionStrategyMock.swift
//  ProtonCore-Keymaker-Tests - Created on 14/09/2023.
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

import Foundation
@testable import ProtonCoreKeymaker

final class ProtectionStrategyMock: ProtectionStrategy {

    var underlyingKeychain: Keychain!
    var keychain: Keychain {
        get { underlyingKeychain }
        set { underlyingKeychain = newValue }
    }

    static var underlyingKeychainLabel: String!
    static var keychainLabel: String {
        get { underlyingKeychainLabel }
        set { underlyingKeychainLabel = newValue }
    }

    init() { }

    var lockValueClosure: ((MainKey) throws -> Void)!
    func lock(value: MainKey) throws {
        try lockValueClosure(value)
    }

    var unlockCypherBitsClosure: ((Data) throws -> MainKey)!
    func unlock(cypherBits: Data) throws -> MainKey {
        return try unlockCypherBitsClosure(cypherBits)
    }
}
