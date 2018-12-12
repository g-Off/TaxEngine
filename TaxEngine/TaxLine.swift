//
//  TaxLine.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-17.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// A finalized tax calculation for a item/tax combination.
public struct TaxLine: CustomStringConvertible, Codable  {
	/// The identifier of the item that this line was computed from.
	public let itemKey: ItemKey
	/// The identifier for the tax that this line was computed using.
	public let taxRateKey: TaxRate.Key
	/// The total amount of tax to be charged rounded to the currencies decimal places.
	public internal(set) var amount: Decimal
	
	private enum CodingKeys: String, CodingKey {
		case itemKey
		case taxRateKey
		case amount
	}
	
    init(itemKey: ItemKey, taxRateKey: TaxRate.Key, amount: Decimal) {
        self.itemKey = itemKey
        self.taxRateKey = taxRateKey
        self.amount = amount
    }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.itemKey = try container.decode(ItemKey.self, forKey: .itemKey)
		self.taxRateKey = try container.decode(TaxRate.Key.self, forKey: .taxRateKey)
		self.amount = try container.decodeDecimal(forKey: .amount)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(itemKey, forKey: .itemKey)
		try container.encode(taxRateKey, forKey: .taxRateKey)
		try container.encodeDecimal(amount, forKey: .amount)
	}
	
	public var description: String {
		return "\(amount.description), \(taxRateKey)"
	}
}

extension TaxLine: Equatable {
	public static func ==(lhs: TaxLine, rhs: TaxLine) -> Bool {
		return lhs.itemKey == rhs.itemKey && lhs.taxRateKey == rhs.taxRateKey && lhs.amount == rhs.amount
	}
}

extension TaxLine: CustomDebugStringConvertible {
	public var debugDescription: String {
		return description
	}
}
