//
//  DisabledTaxRuleTests.swift
//  TaxEngineTests
//
//  Created by Geoffrey Foster on 2018-02-22.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import XCTest
@testable import TaxEngine

class DisabledTaxRuleTests: XCTestCase {
	func testRoundingErrors() throws {
		let gst = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.05")!, type: .normal, zone: .country)
		let pst = TaxRate(key: "tax:country:pst", rate: Decimal(string: "0.08")!, type: .normal, zone: .province)
		let federalTaxExemptItem = Sale(key: "item:1", quantity: 1, unitPrice: 100)
		let taxableItems = [
			federalTaxExemptItem,
			Sale(key: "item:2", quantity: 1, unitPrice: 1)
		]
		let rule = DisabledTaxRule(tax: gst.key, disabledItems: [federalTaxExemptItem.key])
		let taxes = Taxes(currency: .CAD, taxes: [gst, pst], taxableItems: taxableItems, location: .Ottawa(), rules: [rule])
		
		let federalTaxExemptItemTaxLines = taxes.itemizedTaxes["item:1"]
		XCTAssertEqual(federalTaxExemptItemTaxLines?.count, 1)
		
		let taxLine = taxes.itemizedTaxes["item:1"]?.first
		XCTAssertEqual(taxLine?.tax, pst.key)
		XCTAssertEqual(taxLine?.item, federalTaxExemptItem.key)
		XCTAssertEqual(taxLine?.amount, 8)
		
		let testCase = TaxTestCase(currency: .CAD, location: .Ottawa(), taxesIncluded: false, taxes: [gst, pst], lineItems: taxableItems, rules: [rule])
		add(try attachment(from: testCase))
		
		let data = try JSONEncoder().encode(testCase)
		let testCaseDecoded = try JSONDecoder().decode(TaxTestCase.self, from: data)
		print("hi")
	}
}
