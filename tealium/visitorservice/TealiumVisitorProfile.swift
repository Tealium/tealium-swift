//
//  TealiumVisitorProfile.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/13/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public struct TealiumVisitorProfile: Codable {

    public var audiences: Audiences?
    public var badges: Badges?
    public var booleans: Booleans?
    public var currentVisit: CurrentVisitProfile?
    public var dates: Dates?
    public var arraysOfBooleans: ArraysOfBooleans?
    public var numbers: Numbers?
    public var arraysOfNumbers: ArraysOfNumbers?
    public var tallies: Tallies?
    public var strings: VisitorStrings?
    public var arraysOfStrings: ArraysOfStrings?
    public var setsOfStrings: SetsOfStrings?

    enum CodingKeys: String, CodingKey {
        case audiences = "audiences"
        case badges = "badges"
        case dates = "dates"
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

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    // Handles init from either HTTP response or persistent data (different data structures)
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        do {
            if let audiences = try values.decodeIfPresent([String: String].self, forKey: .audiences) {
               self.audiences = Audiences(from: audiences)
           }

           if let badges = try values.decodeIfPresent([String: Bool].self, forKey: .badges) {
               self.badges = Badges(from: badges)
           }

           if let dates = try values.decodeIfPresent([String: Int64].self, forKey: .dates) {
               self.dates = Dates(from: dates)
           }

           if let booleans = try values.decodeIfPresent([String: Bool].self, forKey: .booleans) {
               self.booleans = Booleans(from: booleans)
           }

           if let arraysOfBooleans = try values.decodeIfPresent([String: [Bool]].self, forKey: .arraysOfBooleans) {
               self.arraysOfBooleans = ArraysOfBooleans(from: arraysOfBooleans)
           }

           if let numbers = try values.decodeIfPresent([String: Double].self, forKey: .numbers) {
               self.numbers = Numbers(from: numbers)
           }

           if let arraysOfNumbers = try values.decodeIfPresent([String: [Double]].self, forKey: .arraysOfNumbers) {
               self.arraysOfNumbers = ArraysOfNumbers(from: arraysOfNumbers)
           }

           if let tallies = try values.decodeIfPresent([String: [String: Float]].self, forKey: .tallies) {
               self.tallies = Tallies(from: tallies)
           }

           if let strings = try values.decodeIfPresent([String: String].self, forKey: .strings) {
               self.strings = VisitorStrings(from: strings)
           }

           if let arraysOfStrings = try values.decodeIfPresent([String: [String]].self, forKey: .arraysOfStrings) {
               self.arraysOfStrings = ArraysOfStrings(from: arraysOfStrings)
           }

           if let setsOfStrings = try values.decodeIfPresent([String: Set<String>].self, forKey: .setsOfStrings) {
               self.setsOfStrings = SetsOfStrings(from: setsOfStrings)
           }
        } catch {
            do {
                 if let audiences = try values.decodeIfPresent(Audiences.self, forKey: .audiences) {
                    self.audiences = audiences
                }

                if let badges = try values.decodeIfPresent(Badges.self, forKey: .badges) {
                    self.badges = badges
                }

                if let dates = try values.decodeIfPresent(Dates.self, forKey: .dates) {
                    self.dates = dates
                }

                 if let booleans = try values.decodeIfPresent(Booleans.self, forKey: .booleans) {
                     self.booleans = booleans
                 }

                 if let arraysOfBooleans = try values.decodeIfPresent(ArraysOfBooleans.self, forKey: .arraysOfBooleans) {
                    self.arraysOfBooleans = arraysOfBooleans
                }

                 if let numbers = try values.decodeIfPresent(Numbers.self, forKey: .numbers) {
                     self.numbers = numbers
                 }

                 if let arraysOfNumbers = try values.decodeIfPresent(ArraysOfNumbers.self, forKey: .arraysOfNumbers) {
                    self.arraysOfNumbers = arraysOfNumbers
                 }

                if let tallies = try values.decodeIfPresent(Tallies.self, forKey: .tallies) {
                    self.tallies = tallies
                }

                if let strings = try values.decodeIfPresent(VisitorStrings.self, forKey: .strings) {
                    self.strings = strings
                }

                if let arraysOfStrings = try values.decodeIfPresent(ArraysOfStrings.self, forKey: .arraysOfStrings) {
                    self.arraysOfStrings = arraysOfStrings
                }

                if let setsOfStrings = try values.decodeIfPresent(SetsOfStrings.self, forKey: .setsOfStrings) {
                    self.setsOfStrings = setsOfStrings
                }
            } catch let error {
                throw error
            }
        }

        currentVisit = try values.decodeIfPresent(CurrentVisitProfile.self, forKey: .currentVisit)
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

public struct CurrentVisitProfile: Codable {

    public var dates: Dates?
    public var booleans: Booleans?
    public var arraysOfBooleans: ArraysOfBooleans?
    public var numbers: Numbers?
    public var arraysOfNumbers: ArraysOfNumbers?
    public var tallies: Tallies?
    public var strings: VisitorStrings?
    public var arraysOfStrings: ArraysOfStrings?
    public var setsOfStrings: SetsOfStrings?

    enum CodingKeys: String, CodingKey {
        case dates = "dates"
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

        do {
           if let dates = try values.decodeIfPresent([String: Int64].self, forKey: .dates) {
               self.dates = Dates(from: dates)
           }

           if let booleans = try values.decodeIfPresent([String: Bool].self, forKey: .booleans) {
               self.booleans = Booleans(from: booleans)
           }

           if let arraysOfBooleans = try values.decodeIfPresent([String: [Bool]].self, forKey: .arraysOfBooleans) {
               self.arraysOfBooleans = ArraysOfBooleans(from: arraysOfBooleans)
           }

           if let numbers = try values.decodeIfPresent([String: Double].self, forKey: .numbers) {
               self.numbers = Numbers(from: numbers)
           }

           if let arraysOfNumbers = try values.decodeIfPresent([String: [Double]].self, forKey: .arraysOfNumbers) {
               self.arraysOfNumbers = ArraysOfNumbers(from: arraysOfNumbers)
           }

           if let tallies = try values.decodeIfPresent([String: [String: Float]].self, forKey: .tallies) {
               self.tallies = Tallies(from: tallies)
           }

           if let strings = try values.decodeIfPresent([String: String].self, forKey: .strings) {
               self.strings = VisitorStrings(from: strings)
           }

           if let arraysOfStrings = try values.decodeIfPresent([String: [String]].self, forKey: .arraysOfStrings) {
               self.arraysOfStrings = ArraysOfStrings(from: arraysOfStrings)
           }

           if let setsOfStrings = try values.decodeIfPresent([String: Set<String>].self, forKey: .setsOfStrings) {
               self.setsOfStrings = SetsOfStrings(from: setsOfStrings)
           }
        } catch {
            do {
                if let dates = try values.decodeIfPresent(Dates.self, forKey: .dates) {
                    self.dates = dates
                }

                 if let booleans = try values.decodeIfPresent(Booleans.self, forKey: .booleans) {
                     self.booleans = booleans
                 }

                 if let arraysOfBooleans = try values.decodeIfPresent(ArraysOfBooleans.self, forKey: .arraysOfBooleans) {
                    self.arraysOfBooleans = arraysOfBooleans
                }

                 if let numbers = try values.decodeIfPresent(Numbers.self, forKey: .numbers) {
                     self.numbers = numbers
                 }

                 if let arraysOfNumbers = try values.decodeIfPresent(ArraysOfNumbers.self, forKey: .arraysOfNumbers) {
                    self.arraysOfNumbers = arraysOfNumbers
                 }

                if let tallies = try values.decodeIfPresent(Tallies.self, forKey: .tallies) {
                    self.tallies = tallies
                }

                if let strings = try values.decodeIfPresent(VisitorStrings.self, forKey: .strings) {
                    self.strings = strings
                }

                if let arraysOfStrings = try values.decodeIfPresent(ArraysOfStrings.self, forKey: .arraysOfStrings) {
                    self.arraysOfStrings = arraysOfStrings
                }

                if let setsOfStrings = try values.decodeIfPresent([SetOfStrings].self, forKey: .setsOfStrings) {
                    self.setsOfStrings = setsOfStrings
                }
            } catch let error {
                throw error
            }
    }
        // swiftlint:enable cyclomatic_complexity
        // swiftlint:enable function_body_length
}
}
