//
//  Taxes.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

public struct Taxes: Codable {
	public let currency: Currency
	public let fragments: [TaxLineFragment]
	/// All of the tax lines on a per line item basis. Each tax line is rounded and adjusted for the currency.
	public let taxLines: [TaxLine]
	
	public init(currency: Currency, taxes: [TaxRate], taxesIncluded: Bool = false, taxableItems: [TaxableItem], location: Location, rules: [TaxRule] = []) {
		self.currency = currency
		let fragments = Taxes.calculateFragments(currency: currency, taxes: taxes, taxesIncluded: taxesIncluded, taxableItems: taxableItems, location: location, rules: rules)
		self.fragments = fragments
		self.taxLines = Taxes.computeTaxLines(from: fragments, currency: currency)
	}
	
	/// Total tax by tax rate.
	var collectedTaxes: [TaxRate.Key: Decimal] {
		var collectedTaxes: [TaxRate.Key: Decimal] = [:]
		taxLines.forEach { taxLine in
			collectedTaxes[taxLine.tax, default: Decimal(0)] += taxLine.amount
		}
		return collectedTaxes
	}
	
	var itemizedTaxes: [ItemKey: [TaxLine]] {
		var itemizedTaxes: [ItemKey: [TaxLine]] = [:]
		taxLines.forEach { taxLine in
			itemizedTaxes[taxLine.item, default: []].append(taxLine)
		}
		return itemizedTaxes
	}
	
	// MARK: - Private API
	
	private struct DefaultRule: TaxRule {
		static let key = TaxRuleKey("rule:builtin:default")
		func applies(to lineItem: TaxableItem, location: Location, tax: TaxRate) -> Bool {
			return true
		}
	}
	
	private static func calculateFragments(currency: Currency, taxes: [TaxRate], taxesIncluded: Bool, taxableItems: [TaxableItem], location: Location, rules: [TaxRule]) -> [TaxLineFragment] {
		func makeTaxLineFragment(for taxableItem: TaxableItem, tax: TaxRate, taxRule: TaxRule, location: Location, totalTax: Decimal) -> TaxLineFragment? {
			let taxableAmount = taxRule.taxableAmount(for: taxableItem, location: location, tax: tax) + (tax.type == .compound ? totalTax : 0)
			let taxRate = taxRule.taxRate(for: taxableItem, location: location, tax: tax)
			let taxAmount = taxRate * taxableAmount
			guard taxAmount > 0 else { return nil }
			return TaxLineFragment(item: taxableItem.key, tax: tax.key, amount: taxAmount)
		}
		
		func taxRule(for item: TaxableItem, tax: TaxRate, location: Location) -> TaxRule {
			return rules.first { $0.applies(to: item, location: location, tax: tax) } ?? DefaultRule()
		}
		
		func adjustForTaxesIncluded(taxLineFragments: inout [TaxLineFragment], item: TaxableItem) {
			let totalTax = taxLineFragments.reduce(Decimal(0)) { (sum, taxLine) -> Decimal in
				return sum + taxLine.amount
			}
			let taxableAmount = item.taxableAmount
			if totalTax + taxableAmount > 0 {
				let scalingFactor = taxableAmount / (totalTax + taxableAmount)
				taxLineFragments.mutatingForEach { (taxLine) in
					taxLine.amount *= scalingFactor
				}
			}
		}
		
		var fragments: [ItemKey: [TaxLineFragment]] = [:]
		taxableItems.forEach { taxableItem in
			var totalTax: Decimal = 0
			var taxLines: [TaxLineFragment] = taxes.compactMap { (tax) in
				let rule = taxRule(for: taxableItem, tax: tax, location: location)
				guard let taxLine = makeTaxLineFragment(for: taxableItem, tax: tax, taxRule: rule, location: location, totalTax: totalTax) else { return nil }
				totalTax += taxLine.amount
				return taxLine
			}
			if taxesIncluded {
				adjustForTaxesIncluded(taxLineFragments: &taxLines, item: taxableItem)
			}
			fragments[taxableItem.key] = taxLines
		}
		
		return fragments.flatMap { return $0.value }
	}
	
	private static func computeTaxLines(from fragments: [TaxLineFragment], currency: Currency) -> [TaxLine] {
		func addressRoundingErrors(key: TaxRate.Key, aggregate: Decimal, taxLines: inout [TaxLine]) {
			guard currency.minorUnits > 0 else { return }
			let linesForTaxFromLineItem = taxLines.filter { $0.tax == key }
			var difference = aggregate - linesForTaxFromLineItem.reduce(Decimal(0), { return $0 + $1.amount.rounded(scale: currency.minorUnits) })
			let toTake = Decimal(difference > 0 ? 1 : -1) / pow(Decimal(10), Int(currency.minorUnits))
			
			var i = 0
			while difference != 0 {
				taxLines[i].amount += toTake
				difference -= toTake
				i += 1
				if i == taxLines.count {
					i = 0
				}
			}
		}
		
		var fragmentAggregates: [TaxRate.Key: Decimal] {
			var aggregates: [TaxRate.Key: Decimal] = [:]
			fragments.forEach { (taxLine) in
				aggregates[taxLine.tax, default: Decimal(0)] += taxLine.amount
			}
			return aggregates
		}
		
		var taxLines: [TaxLine] = fragments.map { return TaxLine(item: $0.item, tax: $0.tax, amount: $0.amount) }
		fragmentAggregates.forEach { (taxKey, aggregate) in
			addressRoundingErrors(key: taxKey, aggregate: aggregate.rounded(scale: currency.minorUnits), taxLines: &taxLines)
		}
		
		taxLines.mutatingForEach {
			$0.amount = $0.amount.rounded(scale: currency.minorUnits)
		}
		
		return taxLines
	}
}

extension Taxes: Equatable {
	public static func ==(lhs: Taxes, rhs: Taxes) -> Bool {
		return lhs.currency == rhs.currency && lhs.fragments == rhs.fragments
	}
}

private extension Array {
	mutating func mutatingForEach(_ body: (inout Element) throws -> Void) rethrows {
		for i in indices {
			var element = self[i]
			try body(&element)
			self[i] = element
		}
	}
}
