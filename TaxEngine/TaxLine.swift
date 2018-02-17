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
	public let item: ItemKey
	/// The identifier for the tax that this line was computed using.
	public let tax: TaxRate.Key
	/// The total amount of tax to be charged rounded to the currencies decimal places.
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
	
	public var description: String {
		return "\(amount.description), \(tax)"
	}
}

extension TaxLine: Equatable {
	public static func ==(lhs: TaxLine, rhs: TaxLine) -> Bool {
		return lhs.item == rhs.item && lhs.tax == rhs.tax && lhs.amount == rhs.amount
	}
}

extension TaxLine: CustomDebugStringConvertible {
	public var debugDescription: String {
		return description
	}
}
