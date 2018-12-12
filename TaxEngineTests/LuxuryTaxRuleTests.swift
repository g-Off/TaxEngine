//
//  LuxuryTaxRuleTests.swift
//  TaxEngineTests
//
//  Created by Geoffrey Foster on 2018-02-20.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import XCTest
@testable import TaxEngine

class LuxuryTaxRuleTests: XCTestCase {
	func testLuxuryTaxRuleUnderLimit() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .province)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(1))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .Massachusetts(),
			taxRules: [LuxuryTaxRule(exemptItems: [item.key])]
		)
		let x = TaxTestCase(currency: .USD, location: .Massachusetts(), taxesIncluded: false, taxes: [tax], lineItems: [item], rules: [LuxuryTaxRule(exemptItems: [item.key])])
		add(try! attachment(from: x))
		XCTAssertTrue(taxes.taxLines.isEmpty)
	}
	
	func testLuxuryTaxRuleOverLimit() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .province)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(200))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .Massachusetts(),
			taxRules: [LuxuryTaxRule(exemptItems: [item.key])]
		)
		XCTAssertRate(taxes: taxes, rate: tax, amount: "2.5")
	}
	
	func testLuxuryTaxInapplicableItem() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .province)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(200))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .Massachusetts(),
			taxRules: [LuxuryTaxRule(exemptItems: ["different item"])]
		)
		XCTAssertRate(taxes: taxes, rate: tax, amount: "20")
	}
	
	func testLuxuryTaxInapplicableLocationState() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .province)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(200))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .NewYork(zip: "", county: "", city: ""),
			taxRules: [LuxuryTaxRule(exemptItems: ["different item"])]
		)
		XCTAssertRate(taxes: taxes, rate: tax, amount: "20")
	}
	
	func testLuxuryTaxInapplicableLocationCountry() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .province)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(200))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .London(),
			taxRules: [LuxuryTaxRule(exemptItems: [item.key])]
		)
		XCTAssertRate(taxes: taxes, rate: tax, amount: "20")
	}
	
	func testLuxuryTaxInapplicableTax() {
		let tax = TaxRate(key: "tax:state", rate: Decimal(string: "0.1")!, type: .normal, zone: .country)
		let item = Sale(key: "item", quantity: 1, unitPrice: Decimal(200))
		let taxes = Taxes(
			currency: .USD,
			taxRates: [tax],
			taxableItems: [item],
			location: .Massachusetts(),
			taxRules: [LuxuryTaxRule(exemptItems: [item.key])]
		)
		XCTAssertRate(taxes: taxes, rate: tax, amount: "20")
	}
}
