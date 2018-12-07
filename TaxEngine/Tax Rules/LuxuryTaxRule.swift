//
//  LuxuryTaxRule.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

struct LuxuryTaxRule: TaxRule, Codable {
	static let key = TaxRuleKey("rule:builtin:luxury")
	let thresholds = [
		"MA": Decimal(175),
		"RI": Decimal(250)
	]
	private let exemptItems: Set<ItemKey>
	
	private enum CodingKeys: String, CodingKey {
		case exemptItems
	}
	
    public init(exemptItems: Set<ItemKey>) {
        self.exemptItems = exemptItems
    }
	
	func taxableAmount(for lineItem: TaxableItem, location: Location, tax: TaxRate) -> Decimal {
		guard let threshold = thresholds[location.provinceCode] else { return lineItem.taxableAmount }
		return max(lineItem.taxableAmount - (threshold * lineItem.quantity), 0)
	}
	
	func applies(to lineItem: TaxableItem, location: Location, tax: TaxRate) -> Bool {
		guard location.countryCode == "US" else { return false }
		guard tax.zone == .province else { return false }
		guard let _ = thresholds[location.provinceCode] else { return false }
		guard exemptItems.contains(lineItem.key) else { return false }
		return true
	}
}
