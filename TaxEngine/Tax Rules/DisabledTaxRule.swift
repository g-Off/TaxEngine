//
//  DisabledTaxRule.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-03-01.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// The `DisabledTaxRule` allows for the opting out of a tax rate for a collection of items.
/// What this means is that a product can have its federal tax rate disabled while still charging provincial taxes.
public struct DisabledTaxRule: TaxRule, Codable {
	public static let key = TaxRuleKey("rule:builtin:disabled")
	let tax: TaxRate.Key
	let disabledItems: Set<ItemKey>
	
	public init(tax: TaxRate.Key, disabledItems: Set<ItemKey>) {
		self.tax = tax
		self.disabledItems = disabledItems
	}
	
	public func applies(to lineItem: TaxableItem, location: Location, tax: TaxRate) -> Bool {
		return self.tax == tax.key && disabledItems.contains(lineItem.key)
	}
	
	public func taxableAmount(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal {
		return 0
	}
	
	public func taxRate(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal {
		return 0
	}
}
