//
//  TealiumVisitorProfileAttributes.swift
//  tealium-swift
//
//  Created by Christina Sund on 8/23/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias Audiences = [Audience]
public struct Audience: Codable {
    public let id: String
    public let name: String
}

public extension Audiences {
    init(from dictionary: [String: String]) {
        var audiences = [Audience]()
        dictionary.forEach {
            audiences.append(Audience(id: $0.key, name: $0.value))
        }
        self = audiences
    }

    subscript(name name: String) -> Bool {
        return self.filter {
            $0.name.lowercased() == name.lowercased()
        }.count > 0
    }

    subscript(id id: String) -> Bool {
        return self.filter {
            $0.id.contains(id)
        }.count > 0
    }
}

public typealias Badges = [Badge]
public struct Badge: Codable {
    public let id: String
    public let value: Bool
}

public extension Badges {
    init(from dictionary: [String: Bool]) {
        var badges = [Badge]()
        dictionary.forEach {
            badges.append(Badge(id: $0.key, value: $0.value))
        }
        self = badges
    }

    subscript(id: String) -> Bool {
        return self.filter {
            $0.id == id
        }.count > 0
    }
}

public typealias Dates = [DateTime]
public struct DateTime: Codable {
    public let id: String
    public let value: Int64
}

public extension Dates {
    init(from dictionary: [String: Int64]) {
        var dates = [DateTime]()
        dictionary.forEach {
            dates.append(DateTime(id: $0.key, value: $0.value))
        }
        self = dates
    }

    subscript(id: String) -> Int64? {
        var value: Int64?
        self.forEach { date in
            if date.id == id {
                value = date.value
            }
        }
        return value
    }
}

public typealias Booleans = [Boolean]
public struct Boolean: Codable {
    public let id: String
    public let value: Bool
}

public extension Booleans {
    init(from dictionary: [String: Bool]) {
        var bools = [Boolean]()
        dictionary.forEach {
            bools.append(Boolean(id: $0.key, value: $0.value))
        }
        self = bools
    }

    subscript(id: String) -> Bool? {
        var value: Bool?
        self.forEach { bool in
            if bool.id == id {
                value = bool.value
            }
        }
        return value
    }
}

public typealias ArraysOfBooleans = [ArrayOfBooleans]
public struct ArrayOfBooleans: Codable {
    public let id: String
    public let value: [Bool]
}

public extension ArraysOfBooleans {
    init(from dictionary: [String: [Bool]]) {
        var arraysOfBools = [ArrayOfBooleans]()
        dictionary.forEach {
            arraysOfBools.append(ArrayOfBooleans(id: $0.key, value: $0.value))
        }
        self = arraysOfBools
    }

    subscript(id: String) -> [Bool]? {
        var value: [Bool]?
        self.forEach { boolArr in
            if boolArr.id == id {
                value = boolArr.value
            }
        }
        return value
    }
}

public typealias Numbers = [Number]
public struct Number: Codable {
    public let id: String
    public let value: Double
}

public extension Numbers {
    init(from dictionary: [String: Double]) {
        var numbers = [Number]()
        dictionary.forEach {
            numbers.append(Number(id: $0.key, value: $0.value))
        }
        self = numbers
    }

    subscript(id: String) -> Double? {
        var value: Double?
        self.forEach { number in
            if number.id == id {
                value = number.value
            }
        }
        return value
    }
}

public typealias ArraysOfNumbers = [ArrayOfNumbers]
public struct ArrayOfNumbers: Codable {
    public let id: String
    public let value: [Double]
}

public extension ArraysOfNumbers {
    init(from dictionary: [String: [Double]]) {
        var arraysOfNumbers = [ArrayOfNumbers]()
        dictionary.forEach {
            arraysOfNumbers.append(ArrayOfNumbers(id: $0.key, value: $0.value))
        }
        self = arraysOfNumbers
    }

    subscript(id: String) -> [Double]? {
        var value: [Double]?
        self.forEach { numberArr in
            if numberArr.id == id {
                value = numberArr.value
            }
        }
        return value
    }
}

public typealias Tallies = [Tally]
public struct Tally: Codable {
    public let id: String
    public var tallyValue: [TallyValue]

    init(id: String, tallyValue: [String: Float]) {
        self.id = id
        var tallies = [TallyValue]()
        tallyValue.forEach {
            tallies.append(TallyValue(key: $0.key, count: $0.value))
        }
        self.tallyValue = tallies
    }

}

public extension Tallies {
    init(from dictionary: [String: [String: Float]]) {
        var tallies = [Tally]()
        dictionary.forEach {
            tallies.append(Tally(id: $0.key, tallyValue: $0.value))
        }
        self = tallies
    }

    subscript(tally id: String) -> Tally? {
        var value: Tally?
        self.forEach { tally in
            if tally.id == id {
                value = tally
            }
        }
        return value
    }

    subscript(tally id: String, key key: String) -> Float? {
        var value: Float?
        self.forEach { tally in
            if tally.id == id {
                value = tally.tallyValue[key]?.count
            }
        }
        return value
    }
}

public typealias TallyValues = [TallyValue]
public struct TallyValue: Codable {
    public let key: String
    public let count: Float
}

public extension TallyValues {
    subscript(key: String) -> TallyValue? {
        var value: TallyValue?
        self.forEach { tallyValue in
            if tallyValue.key == key {
                value = tallyValue
            }
        }
        return value
    }
}

public typealias VisitorStrings = [VisitorString]
public struct VisitorString: Codable {
    public let id: String
    public let value: String
}

public extension VisitorStrings {
    init(from dictionary: [String: String]) {
        var strings = [VisitorString]()
        dictionary.forEach {
            strings.append(VisitorString(id: $0.key, value: $0.value))
        }
        self = strings
    }

    subscript(id: String) -> String? {
        var value: String?
        self.forEach { string in
            if string.id == id {
                value = string.value
            }
        }
        return value
    }
}

public typealias SetsOfStrings = [SetOfStrings]
public struct SetOfStrings: Codable {
    public let id: String
    public let value: Set<String>
}

public extension SetsOfStrings {
    init(from dictionary: [String: Set<String>]) {
        var setsOfStrings = [SetOfStrings]()
        dictionary.forEach {
            setsOfStrings.append(SetOfStrings(id: $0.key, value: $0.value))
        }
        self = setsOfStrings
    }

    subscript(id: String) -> Set<String>? {
        var value: Set<String>?
        self.forEach { setOfStrings in
            if setOfStrings.id == id {
                value = setOfStrings.value
            }
        }
        return value
    }
}

public typealias ArraysOfStrings = [ArrayOfStrings]
public struct ArrayOfStrings: Codable {
    public let id: String
    public let value: [String]
}

public extension ArraysOfStrings {
    init(from dictionary: [String: [String]]) {
        var arraysOfStrings = [ArrayOfStrings]()
        dictionary.forEach {
            arraysOfStrings.append(ArrayOfStrings(id: $0.key, value: $0.value))
        }
        self = arraysOfStrings
    }

    subscript(id: String) -> [String]? {
        var value: [String]?
        self.forEach { stringArray in
            if stringArray.id == id {
                value = stringArray.value
            }
        }
        return value
    }
}
