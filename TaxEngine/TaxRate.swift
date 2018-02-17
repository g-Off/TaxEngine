//
//  TaxRate.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

/// <#Description#>
public struct TaxRate: Codable {
	/// How the tax calculations are applied. Most taxes should be done using `normal`, but occasionally `compound` might be necessary
	///
	/// - normal: Taxes will only be computed on the items taxable amount
	/// - compound: Taxes will be computed on top of prior amounts (item amount + previous tax)
	public enum ApplicationType: String, Codable {
		case normal
		case compound
	}
	
	public enum Zone: String, Codable {
		case country
		case province
		case county
		case city
		case custom
	}
	
	/// Represents a unique key for taxes. This is what all taxes will be collected under.
	/// For example, taxes for each line item are computed and then all those with the key of "gst" are collected together
	public struct Key: RawRepresentable, Codable {
		public let rawValue: String
		
		public init(_ string: String) {
			self.rawValue = string
		}
		
		public init(rawValue: String) {
			self.init(rawValue)
		}
	}
	
	public let key: Key
	public var rate: Decimal
	public var type: ApplicationType
	public var zone: Zone
	
	private enum CodingKeys: String, CodingKey {
		case key
		case type
		case zone
		case rate
	}
	
    public init(key: Key, rate: Decimal, type: ApplicationType = .normal, zone: Zone) {
        self.key = key
        self.type = type
        self.zone = zone
        self.rate = rate
    }
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.key = try container.decode(Key.self, forKey: .key)
		self.rate = try container.decodeDecimal(forKey: .rate)
		self.type = try container.decode(ApplicationType.self, forKey: .type)
		self.zone = try container.decode(Zone.self, forKey: .zone)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(key, forKey: .key)
		try container.encodeDecimal(rate, forKey: .rate)
		try container.encode(type, forKey: .type)
		try container.encode(zone, forKey: .zone)
	}
}

extension TaxRate: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		return "\(key) @ \(rate * 100)% \(type)"
	}
	
	public var debugDescription: String {
		return description
	}
}

extension TaxRate: Hashable {
	public var hashValue: Int {
		return key.rawValue.hashValue
	}

	public static func ==(lhs: TaxRate, rhs: TaxRate) -> Bool {
		return lhs.key == rhs.key
	}
}

extension TaxRate.Key: Hashable {
	public var hashValue: Int {
		return rawValue.hashValue
	}
}

extension TaxRate.Key: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value)
	}
}
