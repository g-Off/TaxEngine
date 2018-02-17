//
//  Utilities.swift
//  TaxEngineTests
//
//  Created by Geoffrey Foster on 2018-02-21.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import XCTest
@testable import TaxEngine

func XCTAssertRate(taxes: Taxes, rate: TaxRate, amount: String, file: StaticString = #file, line: UInt = #line) {
	XCTAssertEqual(taxes.collectedTaxes[rate.key], Decimal(string: amount)!, file: file, line: line)
}

func XCTAssertHasTax(taxes: Taxes, rate: TaxRate, file: StaticString = #file, line: UInt = #line) {
	XCTAssertNotNil(taxes.collectedTaxes[rate.key], file: file, line: line)
}

func XCTAssertNoTaxes(_ taxes: Taxes, file: StaticString = #file, line: UInt = #line) {
	XCTAssertTrue(taxes.taxLines.isEmpty, file: file, line: line)
}

func attachment<T: Encodable>(from codable: T, function: String = #function) throws -> XCTAttachment {
	let encoder = JSONEncoder()
	encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
	let data = try encoder.encode(codable)
	let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
	attachment.lifetime = .keepAlways
	attachment.name = function
	return attachment
}

struct Sale: TaxableItem, Codable, Equatable {
	var key: ItemKey
	var quantity: Decimal
	var unitPrice: Decimal
	var taxableAmount: Decimal {
		return quantity * unitPrice
	}
	
	public static func ==(lhs: Sale, rhs: Sale) -> Bool {
		return lhs.key == rhs.key &&
			lhs.quantity == rhs.quantity &&
			lhs.unitPrice == rhs.unitPrice
	}
}

struct TaxTestCase: Codable {
	private struct TaxRuleWrapper: Codable {
		private enum CodingKeys: String, CodingKey {
			case key
		}
		let taxRule: TaxRule
		
		init(taxRule: TaxRule) {
			self.taxRule = taxRule
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let key = try container.decode(TaxRuleKey.self, forKey: .key)
			switch key {
			case DisabledTaxRule.key:
				self.taxRule = try DisabledTaxRule(from: decoder)
			case LuxuryTaxRule.key:
				self.taxRule = try LuxuryTaxRule(from: decoder)
			case NewYorkClothingTaxRule.key:
				self.taxRule = try NewYorkClothingTaxRule(from: decoder)
			default:
				throw DecodingError.typeMismatch(TaxRule.self, DecodingError.Context(codingPath: [], debugDescription: "Unknown rule type: \(key)"))
			}
		}
		
		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type(of: taxRule).key, forKey: .key)
			guard let encodableRule = taxRule as? TaxRule & Encodable else {
				throw EncodingError.invalidValue(taxRule, EncodingError.Context(codingPath: [], debugDescription: ""))
			}
			try encodableRule.encode(to: encoder)
		}
	}
	
	private enum CodingKeys: String, CodingKey {
		case currency
		case lineItems
		case location
		case taxesIncluded
		case taxes
		case rules
		case results
	}
	
	let currency: Currency
	let lineItems: [Sale]
	let location: Location
	let taxesIncluded: Bool
	let taxes: [TaxRate]
	let rules: [TaxRule]
	let results: Taxes
	
	init(currency: Currency, location: Location, taxesIncluded: Bool, taxes: [TaxRate], lineItems: [Sale], rules: [TaxRule]) {
		self.currency = currency
		self.lineItems = lineItems
		self.location = location
		self.taxesIncluded = taxesIncluded
		self.taxes = taxes
		self.rules = rules
		self.results = Taxes(currency: currency, taxes: taxes, taxesIncluded: taxesIncluded, taxableItems: lineItems, location: location, rules: rules)
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.currency = try container.decode(Currency.self, forKey: .currency)
		self.lineItems = try container.decode([Sale].self, forKey: .lineItems)
		self.location = try container.decode(Location.self, forKey: .location)
		self.taxesIncluded = try container.decode(Bool.self, forKey: .taxesIncluded)
		self.taxes = try container.decode([TaxRate].self, forKey: .taxes)
		self.rules = try container.decodeIfPresent([TaxRuleWrapper].self, forKey: .rules)?.map { $0.taxRule } ?? []
		self.results = try container.decode(Taxes.self, forKey: .results)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(currency, forKey: .currency)
		try container.encode(lineItems, forKey: .lineItems)
		try container.encode(location, forKey: .location)
		try container.encode(taxesIncluded, forKey: .taxesIncluded)
		try container.encode(taxes, forKey: .taxes)
		if !rules.isEmpty {
			try container.encode(rules.compactMap({ TaxRuleWrapper(taxRule: $0) }), forKey: .rules)
		}
		try container.encode(results, forKey: .results)
	}
}

extension TaxTestCase: Equatable {
	public static func ==(lhs: TaxTestCase, rhs: TaxTestCase) -> Bool {
		func compare(lhs: [TaxRule], rhs: [TaxRule]) -> Bool {
			return lhs.map { type(of: $0).key } == rhs.map { type(of: $0).key }
		}
		return lhs.currency == rhs.currency &&
			lhs.lineItems == rhs.lineItems &&
			lhs.location == rhs.location &&
			lhs.taxesIncluded == rhs.taxesIncluded &&
			lhs.taxes == rhs.taxes &&
			compare(lhs: lhs.rules, rhs: rhs.rules)
	}
}

extension Currency {
	static var CAD = Currency(code: "CAD", minorUnits: 2)
	static var USD = Currency(code: "USD", minorUnits: 2)
	static var GBP = Currency(code: "GBP", minorUnits: 2)
	static var JPY = Currency(code: "JPY", minorUnits: 0)
}

extension Location {
	static func Massachusetts() -> Location {
		return Location(countryCode: "US", countryName: "United States", provinceCode: "MA", provinceName: "Massachusetts", county: "", city: "", postalCode: "")
	}
	
	static func NewYork(zip: String, county: String, city: String) -> Location {
		return Location(countryCode: "US", countryName: "United States", provinceCode: "NY", provinceName: "New York", county: county, city: city, postalCode: zip)
	}
	
	static func Ottawa() -> Location {
		return Location(countryCode: "CA", countryName: "Canada", provinceCode: "ON", provinceName: "Ontario", county: "", city: "Ottawa", postalCode: "K2P 0R4")
	}
	
	static func London() -> Location {
		return Location(countryCode: "UK", countryName: "United Kingdom", provinceCode: "", provinceName: "", county: "", city: "London", postalCode: "WC2N 5DU")
	}
	
	static func Tokyo() -> Location {
		return Location(countryCode: "JP", countryName: "Japan", provinceCode: "", provinceName: "", county: "", city: "Tokyo", postalCode: "863-1201")
	}
}
