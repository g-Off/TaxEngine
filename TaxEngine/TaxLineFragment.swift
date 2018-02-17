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
	public let item: ItemKey
	public let tax: TaxRate.Key
	public internal(set) var amount: Decimal
	
	private enum CodingKeys: String, CodingKey {
		case item
		case tax
		case amount
	}
	
	init(item: ItemKey, tax: TaxRate.Key, amount: Decimal) {
		self.item = item
		self.tax = tax
		self.amount = amount
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.item = try container.decode(ItemKey.self, forKey: .item)
		self.tax = try container.decode(TaxRate.Key.self, forKey: .tax)
		self.amount = try container.decodeDecimal(forKey: .amount)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(item, forKey: .item)
		try container.encode(tax, forKey: .tax)
		try container.encodeDecimal(amount, forKey: .amount)
	}
}

extension TaxLineFragment: Equatable {
	public static func ==(lhs: TaxLineFragment, rhs: TaxLineFragment) -> Bool {
		return lhs.item == rhs.item && lhs.tax == rhs.tax && lhs.amount == rhs.amount
	}
}

extension TaxLineFragment: CustomStringConvertible {
	public var description: String {
		return "\(amount.description), \(tax)"
	}
}

extension TaxLineFragment: CustomDebugStringConvertible {
	public var debugDescription: String {
		return description
	}
}
