//
//  NewYorkTaxRuleTests.swift
//  TaxEngineTests
//
//  Created by Geoffrey Foster on 2018-02-21.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import XCTest
@testable import TaxEngine

class NewYorkTaxRuleTests: XCTestCase {
	private let cityTax = TaxRate(key: "tax:city", rate: 0, type: .normal, zone: .city)
	private let countyTax = TaxRate(key: "tax:county", rate: 0.04875, type: .normal, zone: .county)
	private let stateTax = TaxRate(key: "tax:state", rate: 0.04, type: .normal, zone: .province)
	
	private func taxesForLocation(_ location: Location) -> Taxes {
		let taxes = Taxes(
			currency: .USD,
			taxRates: [cityTax, countyTax, stateTax],
			taxableItems: [Sale(key: "product", quantity: 1, unitPrice: 100)],
			location: location,
			taxRules: [NewYorkClothingTaxRule(exemptItems: ["product"])]
		)
		return taxes
	}
	
	func testNewYorkNoExemptions() {
		let taxes = Taxes(
			currency: .USD,
			taxRates: [cityTax, countyTax, stateTax],
			taxableItems: [Sale(key: "product", quantity: 1, unitPrice: 100)],
			location: .NewYork(zip: "11413", county: "QUEENS", city: "SPRINGFIELD GARDENS")
		)
		//XCTAssertNoTaxes(taxes)
	}
	
	func testNewYorkTaxExemptionUnderAmountNotSubjectToStateTaxAndInNewYorkCityNoCountyOrCityTaxes() {
		let taxes = taxesForLocation(Location.NewYork(zip: "11413", county: "QUEENS", city: "SPRINGFIELD GARDENS"))
		XCTAssertNoTaxes(taxes)
	}
	
	func testNewYorkTaxExemptionSomeCountiesDoNotExemptCountyAndCityTaxes()	{
		let taxes = taxesForLocation(Location.NewYork(zip: "14871", county:"CHEMUNG", city:"PINE CITY"))
//		AssertNoneOrZeroTaxForZone(lineItem, kSHPTaxZoneState);
		XCTAssertHasTax(taxes: taxes, rate: countyTax)
	}
	
	func testNewYorkTaxExemptionChenangoCountyExemptsTaxesOutsideOfNorwich() {
		let taxes = taxesForLocation(Location.NewYork(zip: "13809", county:"CHENANGO", city:"MOUNT UPTON"))
		XCTAssertNoTaxes(taxes);
	}
	
	func testNewYorkTaxExemptionChenangoCountyDoesNotExemptTaxesInsideOfNorwich() {
		let taxes = taxesForLocation(Location.NewYork(zip: "13815", county:"CHENANGO", city:"NORWICH"))
//		AssertNoneOrZeroTaxForZone(lineItem, kSHPTaxZoneState);
		XCTAssertHasTax(taxes: taxes, rate: countyTax)
	}
	
	func testNewYorkTaxExemptionMadisonCountyExemptsTaxesOutsideOfOneida() {
		let taxes = taxesForLocation(Location.NewYork(zip: "13043", county:"MADISON", city:"CLOCKVILLE"))
		XCTAssertNoTaxes(taxes);
	}
	
	func testNewYorkTaxExemptionMadisonCountyExemptsTaxesInsideOfOneida() {
		let taxes = taxesForLocation(Location.NewYork(zip: "13043", county:"MADISON", city:"ONEIDA"))
//		AssertNoneOrZeroTaxForZone(lineItem, kSHPTaxZoneState);
//		AssertHasCityOrCountyTaxes(lineItem);
		XCTAssertHasTax(taxes: taxes, rate: countyTax)
	}
}
