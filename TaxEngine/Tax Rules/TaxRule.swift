//
//  TaxRule.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// Concrete type that wraps a unique identifier for a `TaxRule`
public struct TaxRuleKey: RawRepresentable, Codable {
	public private(set) var rawValue: String
	public init(rawValue: String) {
		self.rawValue = rawValue
	}
	public init(_ rawValue: String) {
		self.init(rawValue: rawValue)
	}
}

extension TaxRuleKey: Equatable, Hashable {
	public var hashValue: Int {
		return self.rawValue.hashValue
	}
	
	public static func ==(lhs: TaxRuleKey, rhs: TaxRuleKey) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}
}

extension TaxRuleKey: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(rawValue: value)
	}
}

/// A tax adjustment rule that can be selectively applied during tax calculations. Examples of this are the clothing tax exemption rules that some states apply where clothing only has provincial tax applied if an item is over a certain value.
public protocol TaxRule {
	/// Unique key for this tax rule.
	static var key: TaxRuleKey { get }
	
	/// Returns whether this rule applies to the given item, at the given location, for the tax rate.
	///
	/// - Returns: `true` if this rule is applied to this `TaxableItem` and `TaxRate` combination, `false` otherwise.
	func applies(to lineItem: TaxableItem, location: Location, tax: TaxRate) -> Bool
	
	/// Returns the amount from the given item that should be taxed. This allows for only taxing a portion of a line items amount.
	func taxableAmount(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal
	
	/// Returns the tax rate to be used. This allows for adjusting of the given `TaxRate`.
	func taxRate(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal
}

extension TaxRule {
	public func taxableAmount(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal {
		return lineItem.taxableAmount
	}
	
	public func taxRate(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal {
		return tax.rate
	}
}
