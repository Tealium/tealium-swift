//
//  MomentsAPIEngineResponse.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct EngineResponse: Codable {
    /// The complete list of audiences the visitor is currently assigned to. Could be the audience name, or just the ID, depending on the options specified in the UI.
    public var audiences: [String] = []
    /// The complete list of badges assigned to the visitor. Could be the badge name, or just the ID, depending on the options specified in the UI.
    public var badges: [String] = []
    /// All audiencestream `Boolean` attributes currently assigned to the visitor
    public var booleans: [String: Bool] = [:]
    /// All audiencestream `Date` attributes currently assigned to the visitor, which are millisecond-precise Unix timestamps
    public var dates: [String: Int64] = [:]
    /// All audiencestream `Number` attributes currently assigned to the visitor
    public var numbers: [String: Double] = [:]
    /// All audiencestream `String` attributes currently assigned to the visitor
    public var strings: [String: String] = [:]
    enum CodingKeys: String, CodingKey {
        case audiences,
             badges,
             booleans = "flags",
             dates,
             numbers = "metrics",
             strings = "properties"
    }
}
