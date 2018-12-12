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
				taxRates: testCase.taxes,
				taxesIncluded: testCase.taxesIncluded,
				taxableItems: testCase.lineItems,
				location: testCase.location,
				taxRules: testCase.rules
			)
			XCTAssertEqual(testCase.results, taxes)
		}
	}
	
	func testBasic() throws {
		let hst = TaxRate(key: "tax:province:hst", rate: Decimal(string: "0.13")!, type: .normal, zone: .province)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: Decimal(string: "1.00")!)
		let taxes = Taxes(currency: .CAD, taxRates: [hst], taxableItems: [lineItem], location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: hst, amount: "0.13")
	}
	
	func testPennyDistribution() throws {
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.07")!, type: .normal, zone: .country)
		let taxableItems = [
			Sale(key: "custom:1", quantity: 1, unitPrice: Decimal(string: "0.49")!),
			Sale(key: "custom:2", quantity: 1, unitPrice: Decimal(string: "0.49")!)
		]
		let taxes = Taxes(currency: .CAD, taxRates: [tax], taxableItems: taxableItems, location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: tax, amount: "0.07")
	}
	
	func testPennyDistributionWithZeroPriceLineItem() throws {
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.07")!, type: .normal, zone: .country)
		let taxableItems = [
			Sale(key: "custom:1", quantity: 1, unitPrice: Decimal(string: "0.0")!),
			Sale(key: "custom:2", quantity: 1, unitPrice: Decimal(string: "0.49")!),
			Sale(key: "custom:3", quantity: 1, unitPrice: Decimal(string: "0.49")!)
		]
		let taxes = Taxes(currency: .CAD, taxRates: [tax], taxableItems: taxableItems, location: .Ottawa())
		XCTAssertEqual(taxes["custom:2", TaxRate.Key("tax:country:gst")], Decimal(string: "0.04"))
		XCTAssertEqual(taxes["custom:3", TaxRate.Key("tax:country:gst")], Decimal(string: "0.03"))
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: tax, amount: "0.07")
	}
	
	func testPennyDistributionAcrossManyLineItems() throws {
		let taxableItems = (0..<10).map {
			Sale(key: ItemKey(rawValue: "custom:\($0)"), quantity: 1, unitPrice: Decimal(string: "0.46")!)
		}
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.08")!, type: .normal, zone: .country)
		let taxes = Taxes(currency: .CAD, taxRates: [tax], taxableItems: taxableItems, location: .Ottawa())
		XCTAssertEqual(taxes[TaxRate.Key("tax:country:gst")], Decimal(string: "0.37"))
		(0..<3).forEach {
			XCTAssertEqual(taxes[ItemKey(rawValue: "custom:\($0)"), TaxRate.Key("tax:country:gst")], Decimal(string: "0.03"))
		}
		(3..<10).forEach {
			XCTAssertEqual(taxes[ItemKey(rawValue: "custom:\($0)"), TaxRate.Key("tax:country:gst")], Decimal(string: "0.04"))
		}
	}
	
	func testZeroDigitDecimalCurrency() throws {
		let tax = TaxRate(key: "tax:country:gst", rate: Decimal(string: "0.07")!, type: .normal, zone: .country)
		let taxableItems = [
			Sale(key: "custom:1", quantity: 1, unitPrice: Decimal(string: "10")!)
		]
		let taxes = Taxes(currency: .JPY, taxRates: [tax], taxableItems: taxableItems, location: .Tokyo())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: tax, amount: "1")
	}
	
	func testCompoundTax() throws {
		let gst = TaxRate(key: "tax:federal:gst", rate: Decimal(string: "0.05")!, type: .normal, zone: .country)
		let qst = TaxRate(key: "tax:province:qst", rate: Decimal(string: "0.095")!, type: .compound, zone: .province)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: Decimal(string: "100.00")!)
		let taxes = Taxes(currency: .CAD, taxRates: [gst, qst], taxableItems: [lineItem], location: .Ottawa())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: gst, amount: "5")
		XCTAssertRate(taxes: taxes, rate: qst, amount: "9.98")
		let testCase = TaxTestCase(currency: .CAD, location: .Ottawa(), taxesIncluded: false, taxes: [gst, qst], lineItems: [lineItem], rules: [])
		add(try attachment(from: testCase))
	}
	
	func testTaxesIncluded() throws {
		let vat = TaxRate(key: "tax:vat", rate: 0.2, type: .normal, zone: .country)
		let lineItem = Sale(key: "Misc", quantity: 1, unitPrice: 100)
		let taxes = Taxes(currency: .GBP, taxRates: [vat], taxesIncluded: true, taxableItems: [lineItem], location: .London())
		try add(attachment(from: taxes))
		XCTAssertRate(taxes: taxes, rate: vat, amount: "16.67")
	}
}
