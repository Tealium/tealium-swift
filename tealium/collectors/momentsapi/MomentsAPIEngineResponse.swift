//
//  MomentsAPIEngineResponse.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct EngineResponse: Codable {
    /// The complete list of audiences the visitor is currently assigned to. Could be the audience name, or just the ID, depending on the options specified in the UI.
    public var audiences: [String]
    /// The complete list of badges assigned to the visitor. Could be the badge name, or just the ID, depending on the options specified in the UI.
    public var badges: [String]
    /// All audiencestream `Boolean` attributes currently assigned to the visitor
    public var booleans: [String: Bool]
    /// All audiencestream `Date` attributes currently assigned to the visitor, which are millisecond-precise Unix timestamps
    public var dates: [String: Int64]
    /// All audiencestream `Number` attributes currently assigned to the visitor
    public var numbers: [String: Double]
    /// All audiencestream `String` attributes currently assigned to the visitor
    public var strings: [String: String]

    enum CodingKeys: String, CodingKey {
        case audiences,
             badges,
             booleans = "flags",
             dates,
             numbers = "metrics",
             strings = "properties"
    }

    public init(audiences: [String] = [],
                badges: [String] = [],
                booleans: [String: Bool] = [:],
                dates: [String: Int64] = [:],
                numbers: [String: Double] = [:],
                strings: [String: String] = [:]) {
        self.audiences = audiences
        self.badges = badges
        self.booleans = booleans
        self.dates = dates
        self.numbers = numbers
        self.strings = strings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.audiences = try container.decodeIfPresent([String].self, forKey: .audiences) ?? []
        self.badges = try container.decodeIfPresent([String].self, forKey: .badges) ?? []
        self.booleans = (try container.decodeIfPresent([String: Bool?].self, forKey: .booleans)?.compactMapValues { $0 }) ?? [:]
        self.dates = (try container.decodeIfPresent([String: Int64?].self, forKey: .dates)?.compactMapValues { $0 }) ?? [:]
        self.numbers = (try container.decodeIfPresent([String: Double?].self, forKey: .numbers)?.compactMapValues { $0 }) ?? [:]
        self.strings = (try container.decodeIfPresent([String: String?].self, forKey: .strings)?.compactMapValues { $0 }) ?? [:]
    }
}
