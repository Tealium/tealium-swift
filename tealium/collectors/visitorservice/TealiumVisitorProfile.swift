//
//  TealiumVisitorProfile.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumVisitorProfile: Codable {
    public var audiences: [String: String]?
    public var badges: [String: Bool]?
    public var dates: [String: Int64]?
    public var booleans: [String: Bool]?
    public var arraysOfBooleans: [String: [Bool]]?
    public var numbers: [String: Double]?
    public var arraysOfNumbers: [String: [Double]]?
    public var tallies: [String: [String: Double]]?
    public var strings: [String: String]?
    public var arraysOfStrings: [String: [String]]?
    public var setsOfStrings: [String: Set<String>]?
    public var currentVisit: TealiumCurrentVisitProfile?

    enum CodingKeys: String, CodingKey {
        case audiences
        case badges
        case dates
        case booleans = "flags"
        case arraysOfBooleans = "flag_lists"
        case numbers = "metrics"
        case arraysOfNumbers = "metric_lists"
        case tallies = "metric_sets"
        case strings = "properties"
        case arraysOfStrings = "property_lists"
        case setsOfStrings = "property_sets"
        case currentVisit = "current_visit"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        audiences = try values.decodeIfPresent([String: String].self, forKey: .audiences)
        badges = try values.decodeIfPresent([String: Bool].self, forKey: .badges)
        dates = try values.decodeIfPresent([String: Int64].self, forKey: .dates)
        booleans = try values.decodeIfPresent([String: Bool].self, forKey: .booleans)
        arraysOfBooleans = try values.decodeIfPresent([String: [Bool]].self, forKey: .arraysOfBooleans)
        numbers = try values.decodeIfPresent([String: Double].self, forKey: .numbers)
        arraysOfNumbers = try values.decodeIfPresent([String: [Double]].self, forKey: .arraysOfNumbers)
        tallies = try values.decodeIfPresent([String: [String: Double]].self, forKey: .tallies)
        strings = try values.decodeIfPresent([String: String].self, forKey: .strings)
        arraysOfStrings = try values.decodeIfPresent([String: [String]].self, forKey: .arraysOfStrings)
        setsOfStrings = try values.decodeIfPresent([String: Set<String>].self, forKey: .setsOfStrings)
        currentVisit = try values.decodeIfPresent(TealiumCurrentVisitProfile.self, forKey: .currentVisit)
    }

    public var isEmpty: Bool {
        return self.audiences == nil &&
            self.badges == nil &&
            self.currentVisit == nil &&
            self.dates == nil &&
            self.booleans == nil &&
            self.arraysOfBooleans == nil &&
            self.numbers == nil &&
            self.arraysOfNumbers == nil &&
            self.tallies == nil &&
            self.strings == nil &&
            self.arraysOfStrings == nil &&
            self.setsOfStrings == nil
    }

}

public struct TealiumCurrentVisitProfile: Codable {
    public var dates: [String: Int64]?
    public var booleans: [String: Bool]?
    public var arraysOfBooleans: [String: [Bool]]?
    public var numbers: [String: Double]?
    public var arraysOfNumbers: [String: [Double]]?
    public var tallies: [String: [String: Double]]?
    public var strings: [String: String]?
    public var arraysOfStrings: [String: [String]]?
    public var setsOfStrings: [String: Set<String>]?

    enum CodingKeys: String, CodingKey {
        case dates
        case booleans = "flags"
        case arraysOfBooleans = "flag_lists"
        case numbers = "metrics"
        case arraysOfNumbers = "metric_lists"
        case tallies = "metric_sets"
        case strings = "properties"
        case arraysOfStrings = "property_lists"
        case setsOfStrings = "property_sets"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        dates = try values.decodeIfPresent([String: Int64].self, forKey: .dates)
        booleans = try values.decodeIfPresent([String: Bool].self, forKey: .booleans)
        arraysOfBooleans = try values.decodeIfPresent([String: [Bool]].self, forKey: .arraysOfBooleans)
        numbers = try values.decodeIfPresent([String: Double].self, forKey: .numbers)
        arraysOfNumbers = try values.decodeIfPresent([String: [Double]].self, forKey: .arraysOfNumbers)
        tallies = try values.decodeIfPresent([String: [String: Double]].self, forKey: .tallies)
        strings = try values.decodeIfPresent([String: String].self, forKey: .strings)
        arraysOfStrings = try values.decodeIfPresent([String: [String]].self, forKey: .arraysOfStrings)
        setsOfStrings = try values.decodeIfPresent([String: Set<String>].self, forKey: .setsOfStrings)
    }
}
