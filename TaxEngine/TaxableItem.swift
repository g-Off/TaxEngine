//
//  TaxableItem.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-20.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// Any type that conforms to this protocol can be used in tax calculations.
public protocol TaxableItem {
	/// Unique line item key. Every line item being injected into the TaxEngine should have a unique key, which can then be used to associate it back to the original line item data model pre-tax engine.
	var key: ItemKey { get }
	/// The total taxable amount. This should take into account the quantity, any discounts or other price adjustments.
	/// For example, if quantity is 2 and the unit price is $1.00, then this should be 2.00
	var taxableAmount: Decimal { get }
	/// The total quantity being represented by this item.
	/// This isn't used in the actual tax calculations but might be taken into account when additional tax adjustments are applied by various `TaxRule` instances.
	var quantity: Decimal { get }
}

/// Concrete type that wraps a unique identifier for a `TaxableItem`
public struct ItemKey: RawRepresentable, Codable {
	public private(set) var rawValue: String
	
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
	
	public init(_ rawValue: String) {
		self.init(rawValue: rawValue)
	}
}

extension ItemKey: Equatable, Hashable {
	public var hashValue: Int {
		return self.rawValue.hashValue
	}
	
	public static func ==(lhs: ItemKey, rhs: ItemKey) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

extension ItemKey: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(rawValue: value)
	}
}
