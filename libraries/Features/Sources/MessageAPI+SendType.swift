//
//  MessageAPI+SendType.swift
//  ProtonCore-Features - Created on 12.04.2018.
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

public struct SendType: OptionSet {
    public let rawValue: Int

    // address package one

    // internal email
    public static let intl    = SendType(rawValue: 1 << 0)
    // encrypt outside
    public static let eo      = SendType(rawValue: 1 << 1)
    // cleartext inline
    public static let cinln   = SendType(rawValue: 1 << 2)
    // inline pgp
    public static let inlnpgp = SendType(rawValue: 1 << 3)

    // address package two MIME

    // pgp mime
    public static let pgpmime = SendType(rawValue: 1 << 4)
    // clear text mime
    public static let cmime   = SendType(rawValue: 1 << 5)
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
