//
//  Decimal+Extensions.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-20.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

extension Decimal {
	/// Rounds the `Decimal` instance according to the provided scale and mode.
	///
	/// - Parameters:
	///   - scale:
	///   - mode: 
	/// - Returns: A new `Decimal` that has been rounded.
	func rounded(scale: UInt8, mode: Decimal.RoundingMode = .plain) -> Decimal {
		var number = self
		var result = Decimal()
		NSDecimalRound(&result, &number, Int(scale), mode)
		return result
	}
}

private let decimalEncodingLocale = Locale(identifier: "en_US_POSIX")

extension KeyedDecodingContainerProtocol {
	func decodeDecimal(forKey key: Self.Key) throws -> Decimal {
		guard let value = Decimal(string: try decode(String.self, forKey: key), locale: decimalEncodingLocale) else {
			throw DecodingError.typeMismatch(Decimal.self, DecodingError.Context(codingPath: [key], debugDescription: ""))
		}
		return value
	}
}

extension KeyedEncodingContainerProtocol {
	mutating func encodeDecimal(_ value: Decimal, forKey key: Self.Key) throws {
		var value = value
		let valueString = NSDecimalString(&value, decimalEncodingLocale)
		try self.encode(valueString, forKey: key)
	}
}
