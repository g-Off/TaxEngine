//
//  TaxLineFragment.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-20.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// Represents an intermediary tax calculation. The `amount` field will be unrounded and represent the exact tax/price amount.
public struct TaxLineFragment: Codable {
	public let itemKey: ItemKey
	public let taxRateKey: TaxRate.Key
	public internal(set) var amount: Decimal
	
	private enum CodingKeys: String, CodingKey {
		case itemKey
		case taxRateKey
		case amount
	}
	
	public init(itemKey: ItemKey, taxRateKey: TaxRate.Key, amount: Decimal) {
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
}

extension TaxLineFragment: Equatable {
	public static func ==(lhs: TaxLineFragment, rhs: TaxLineFragment) -> Bool {
		return lhs.itemKey == rhs.itemKey && lhs.taxRateKey == rhs.taxRateKey && lhs.amount == rhs.amount
	}
}

extension TaxLineFragment: CustomStringConvertible {
	public var description: String {
		return "\(amount.description), \(taxRateKey)"
	}
}

extension TaxLineFragment: CustomDebugStringConvertible {
	public var debugDescription: String {
		return description
	}
}
