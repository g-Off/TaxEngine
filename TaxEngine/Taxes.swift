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
	/// All of the tax lines on a per line item basis. Each tax line is rounded and adjusted for the currency.
	public let taxLines: [TaxLine]
	
	public init(currency: Currency, taxRates: [TaxRate], taxesIncluded: Bool = false, taxableItems: [TaxableItem], location: Location, taxRules: [TaxRule] = []) {
		self.currency = currency
		let fragments = Taxes.calculateFragments(currency: currency, taxes: taxRates, taxesIncluded: taxesIncluded, taxableItems: taxableItems, location: location, rules: taxRules)
		self.taxLines = Taxes.computeTaxLines(from: fragments, currency: currency)
	}
	
	/// Total tax by tax rate.
	public var collectedTaxes: [TaxRate.Key: Decimal] {
		var collectedTaxes: [TaxRate.Key: Decimal] = [:]
		taxLines.forEach { taxLine in
			collectedTaxes[taxLine.taxRateKey, default: Decimal(0)] += taxLine.amount
		}
		return collectedTaxes
	}
	
	public var itemizedTaxes: [ItemKey: [TaxLine]] {
		var itemizedTaxes: [ItemKey: [TaxLine]] = [:]
		taxLines.forEach { taxLine in
			itemizedTaxes[taxLine.itemKey, default: []].append(taxLine)
		}
		return itemizedTaxes
	}
	
	public subscript(_ itemKey: ItemKey) -> [TaxLine] {
		return taxLines.filter { $0.itemKey == itemKey }
	}
	
	public subscript(_ rateKey: TaxRate.Key) -> Decimal {
		return taxLines.filter { $0.taxRateKey == rateKey }.reduce(Decimal(0)) { (result, taxLine) -> Decimal in
			result + taxLine.amount
		}
	}
	
	public subscript(_ itemKey: ItemKey, _ rateKey: TaxRate.Key) -> Decimal {
		return taxLines.filter { $0.itemKey == itemKey && $0.taxRateKey == rateKey }.reduce(Decimal(0)) { (result, taxLine) -> Decimal in
			result + taxLine.amount
		}
	}
	
	// MARK: - Private API
	
	private struct DefaultRule: TaxRule {
		static let key = TaxRuleKey("rule:builtin:default")
		func applies(to lineItem: TaxableItem, location: Location, taxRate: TaxRate) -> Bool {
			return true
		}
	}
	
	private static func calculateFragments(currency: Currency, taxes: [TaxRate], taxesIncluded: Bool, taxableItems: [TaxableItem], location: Location, rules: [TaxRule]) -> [TaxLineFragment] {
		func makeTaxLineFragment(for taxableItem: TaxableItem, taxRate: TaxRate, taxRule: TaxRule, location: Location, totalTax: Decimal) -> TaxLineFragment? {
			let taxableAmount = taxRule.taxableAmount(for: taxableItem, location: location, taxRate: taxRate) + (taxRate.type == .compound ? totalTax : 0)
			let taxRateAmount = taxRule.taxRate(for: taxableItem, location: location, taxRate: taxRate)
			let taxAmount = taxRateAmount * taxableAmount
			guard taxAmount > 0 else { return nil }
			return TaxLineFragment(itemKey: taxableItem.key, taxRateKey: taxRate.key, amount: taxAmount)
		}
		
		func taxRule(for item: TaxableItem, taxRate: TaxRate, location: Location) -> TaxRule {
			return rules.first { $0.applies(to: item, location: location, taxRate: taxRate) } ?? DefaultRule()
		}
		
		func adjustForTaxesIncluded(taxLineFragments: inout [TaxLineFragment], taxableItem: TaxableItem) {
			let totalTax = taxLineFragments.reduce(Decimal(0)) { (sum, fragment) -> Decimal in
				return sum + fragment.amount
			}
			let taxableAmount = taxableItem.taxableAmount
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
			var taxLineFragments: [TaxLineFragment] = taxes.compactMap { (tax) in
				let rule = taxRule(for: taxableItem, taxRate: tax, location: location)
				guard let taxLine = makeTaxLineFragment(for: taxableItem, taxRate: tax, taxRule: rule, location: location, totalTax: totalTax) else { return nil }
				totalTax += taxLine.amount
				return taxLine
			}
			if taxesIncluded {
				adjustForTaxesIncluded(taxLineFragments: &taxLineFragments, taxableItem: taxableItem)
			}
			fragments[taxableItem.key] = taxLineFragments
		}
		
		return taxableItems.flatMap { fragments[$0.key] ?? [] }
	}
	
	private static func computeTaxLines(from fragments: [TaxLineFragment], currency: Currency) -> [TaxLine] {
		func addressRoundingErrors(key: TaxRate.Key, aggregate: Decimal, taxLines: inout [TaxLine]) {
			guard currency.minorUnits > 0 else { return }
			let linesForTaxFromLineItem = taxLines.filter { $0.taxRateKey == key }
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
		
		var fragmentAggregates: [TaxRate.Key: Decimal] = [:]
		fragments.forEach { (taxLine) in
			fragmentAggregates[taxLine.taxRateKey, default: Decimal(0)] += taxLine.amount
		}
		
		var taxLines: [TaxLine] = fragments.map { return TaxLine(itemKey: $0.itemKey, taxRateKey: $0.taxRateKey, amount: $0.amount) }
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
		return lhs.currency == rhs.currency && lhs.taxLines == rhs.taxLines
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
