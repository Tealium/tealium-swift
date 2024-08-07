//
//  MomentsAPIEngineResponse.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct EngineResponse: Codable {
    /// The complete list of audiences the visitor is currently assigned to. Could be the audience name, or just the ID, depending on the options specified in the UI.
    public var audiences: [String]?
    /// The complete list of badges assigned to the visitor. Could be the badge name, or just the ID, depending on the options specified in the UI.
    public var badges: [String]?
    /// All audiencestream `Boolean` attributes currently assigned to the visitor
    public var booleans: [String: Bool]?
    /// All audiencestream `Date` attributes currently assigned to the visitor, which are millisecond-precise Unix timestamps
    public var dates: [String: Int64]?
    /// All audiencestream `Number` attributes currently assigned to the visitor
    public var numbers: [String: Double]?
    /// All audiencestream `String` attributes currently assigned to the visitor
    public var strings: [String: String]?

    enum CodingKeys: String, CodingKey {
        case audiences,
             badges,
             booleans = "flags",
             dates,
             numbers = "metrics",
             strings = "properties"
    }

    public init(audiences: [String]? = nil,
                badges: [String]? = nil,
                booleans: [String: Bool]? = nil,
                dates: [String: Int64]? = nil,
                numbers: [String: Double]? = nil,
                strings: [String: String]? = nil) {
        self.audiences = audiences
        self.badges = badges
        self.booleans = booleans
        self.dates = dates
        self.numbers = numbers
        self.strings = strings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audiences = try container.decodeIfPresent([String].self, forKey: .audiences)
        self.badges = try container.decodeIfPresent([String].self, forKey: .badges)
        self.booleans = try decodeDictionarySkippingNullValues(container: container, key: .booleans)
        self.dates = try decodeDictionarySkippingNullValues(container: container, key: .dates)
        self.numbers = try decodeDictionarySkippingNullValues(container: container, key: .numbers)
        self.strings = try decodeDictionarySkippingNullValues(container: container, key: .strings)
    }

    private func decodeDictionarySkippingNullValues<T: Decodable>(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> [String: T]? {
        guard let nestedContainer = try? container.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key) else {
            return nil
        }
        var result = [String: T]()
        for codingKey in nestedContainer.allKeys {
            if let value = try nestedContainer.decodeIfPresent(T.self, forKey: codingKey) {
                result[codingKey.stringValue] = value
            }
        }
        return result.isEmpty ? nil : result
    }
}

private struct JSONCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        return nil
    }
}
