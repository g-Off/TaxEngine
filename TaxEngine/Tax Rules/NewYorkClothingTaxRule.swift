//
//  NewYorkClothingTaxRule.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

struct NewYorkClothingTaxRule: TaxRule, Codable {
	static let key = TaxRuleKey("rule:builtin:newyork:clothing")
	private let exemptItems: Set<ItemKey>
	private let exemptCounties: Set<String> = [
		"NEW YORK",
		"BRONX",    // the bronx
		"QUEENS",   // queens
		"KINGS",    // brooklyn
		"RICHMOND", // staten island
		"WAYNE",
		"TIOGA",
		"HAMILTON",
		"GREENE",
		"DELAWARE",
		"COLUMBIA",
		"CHAUTAUQUA"
	]
	private let threshold: Decimal = 110
	
	private enum CodingKeys: String, CodingKey {
		case exemptItems
	}
	
	init(exemptItems: Set<ItemKey>) {
		self.exemptItems = exemptItems
	}
	
	func applies(to lineItem: TaxableItem, location: Location, taxRate: TaxRate) -> Bool {
		guard exemptItems.contains(lineItem.key) else { return false }
		guard location.countryCode == "US" else { return false }
		guard location.provinceCode == "NY" else { return false }
		guard taxRate.zone == .province || (taxRate.zone == .county && isCountyExempt(location)) else { return false }
		return true
	}
	
	func taxableAmount(for lineItem: TaxableItem, location: Location, taxRate: TaxRate) -> Decimal {
		if lineItem.taxableAmount < lineItem.quantity * threshold {
			return 0
		} else {
			return lineItem.taxableAmount
		}
	}
	
	private func isCountyExempt(_ location: Location) -> Bool {
		if exemptCounties.contains(location.county) {
			return true
		}
		if location.county == "CHENANGO" {
			return location.city != "NORWICH"
		}
		if location.county == "MADISON" {
			return location.city != "ONEIDA"
		}
		return false
	}
}
