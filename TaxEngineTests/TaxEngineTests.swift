//
//  TaxEngineTests.swift
//  TaxEngineTests
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import XCTest
@testable import TaxEngine

class TaxEngineTests: XCTestCase {
	func testFixtures() throws {
		let bundle = Bundle(for: type(of: self))
		for url in bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [] {
			let data = try Data(contentsOf: url)
			let decoder = JSONDecoder()
			let testCase = try decoder.decode(TaxTestCase.self, from: data)
			let taxes = Taxes(
				currency: testCase.currency,
				taxes: testCase.taxes,
				taxesIncluded: testCase.taxesIncluded,
				taxableItems: testCase.lineItems,
				location: testCase.location,
				rules: testCase.rules
			)
			XCTAssertEqual(testCase.results, taxes)
		}
	}
	
	func testBasic() throws {
		let hst = TaxRate(key: "tax:province:hst", rate: Decimal(string: "0.13")!, type: .normal, zone: .province)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: Decimal(string: "1.00")!)
		let taxes = Taxes(currency: .CAD, taxes: [hst], taxableItems: [lineItem], location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: hst, amount: "0.13")
	}
	
	func testRoundingErrors() throws {
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.07")!, type: .normal, zone: .country)
		let taxableItems = [
			Sale(key: "custom:1", quantity: 1, unitPrice: Decimal(string: "0.49")!),
			Sale(key: "custom:2", quantity: 1, unitPrice: Decimal(string: "0.49")!)
		]
		let taxes = Taxes(currency: .CAD, taxes: [tax], taxableItems: taxableItems, location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: tax, amount: "0.07")
	}
	
	func testZeroDigitDecimalCurrency() throws {
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.07")!, type: .normal, zone: .country)
		let taxableItems = [
			Sale(key: "custom:1", quantity: 1, unitPrice: Decimal(string: "10")!)
		]
		let taxes = Taxes(currency: .JPY, taxes: [tax], taxableItems: taxableItems, location: .Tokyo())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: tax, amount: "1")
	}
	
	func testCompoundTax() throws {
		let gst = TaxRate(key: "tax:federal:gst", rate: Decimal(string: "0.05")!, type: .normal, zone: .country)
		let qst = TaxRate(key: "tax:province:qst", rate: Decimal(string: "0.095")!, type: .compound, zone: .province)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: Decimal(string: "100.00")!)
		let taxes = Taxes(currency: .CAD, taxes: [gst, qst], taxableItems: [lineItem], location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: gst, amount: "5")
		XCTAssertRate(taxes: taxes, rate: qst, amount: "9.98")
		let testCase = TaxTestCase(currency: .CAD, location: .Ottawa(), taxesIncluded: false, taxes: [gst, qst], lineItems: [lineItem], rules: [])
		add(try attachment(from: testCase))
	}
	
	func testTaxesIncluded() throws {
		let vat = TaxRate(key: "tax:vat", rate: 0.2, type: .normal, zone: .country)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: 100)
		let taxes = Taxes(currency: .GBP, taxes: [vat], taxesIncluded: true, taxableItems: [lineItem], location: .London())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: vat, amount: "16.67")
	}
}
