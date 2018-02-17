//
//  Location.swift
//  TaxEngine
//
//  Created by Geoffrey Foster on 2018-02-14.
//  Copyright © 2018 Geoffrey Foster. All rights reserved.
//

import Foundation

public struct Location: Codable {
	public var countryCode: String
	public var countryName: String
	public var provinceCode: String
	public var provinceName: String
	public var county: String
	public var city: String
	public var postalCode: String
	
    public init(countryCode: String, countryName: String, provinceCode: String, provinceName: String, county: String, city: String, postalCode: String) {
        self.countryCode = countryCode
        self.countryName = countryName
        self.provinceCode = provinceCode
        self.provinceName = provinceName
        self.county = county
        self.city = city
        self.postalCode = postalCode
    }
}

extension Location: Equatable {
	public static func ==(lhs: Location, rhs: Location) -> Bool {
		return lhs.countryCode == rhs.countryCode &&
			lhs.provinceCode == rhs.provinceCode &&
			lhs.county == rhs.county &&
			lhs.city == rhs.city &&
			lhs.postalCode == rhs.postalCode
	}
}
