//
//  Currency.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// A basic representation of the currency that tax calculations are being done in.
public struct Currency: Equatable, Codable {
	/// The ISO 4217 currency code
	public let code: String
	/// The number of expected decimal places for this currency.
	/// For example, USD would be 2, JPY would be 0, BHD would be 3. This is used to correctly round the computed tax values.
	public let minorUnits: UInt8
	
    public init(code: String, minorUnits: UInt8) {
        self.code = code
        self.minorUnits = minorUnits
    }
	
	public static func ==(lhs: Currency, rhs: Currency) -> Bool {
		return lhs.code == rhs.code && lhs.minorUnits == rhs.minorUnits
	}
}
