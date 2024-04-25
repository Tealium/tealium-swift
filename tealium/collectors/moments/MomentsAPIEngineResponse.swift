//
//  EngineResponse.swift
//  TealiumMoments
//
//  Created by Craig Rouse on 18/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct EngineResponse: Codable {
    public var attributes: [String: DynamicType] = [:]
    public var audiences: [String] = []
    public var badges: [String] = []
    public var strings: [String] {
        attributes.compactMap {
            $0.value.stringValue
        }
    }
    public var booleans: [Bool] {
        attributes.compactMap {
            $0.value.boolValue
        }
    }
    public var dates: [Int64] = [] {
        attributes.compactMap {
            $0.value.intValue
        }
    }
    
    public var numbers: [Double] = [] {
        attributes.compactMap {
            $0.value.doubleValue
        }
    }

    enum CodingKeys: String, CodingKey {
        case attributes = "properties", audiences, badges
    }
}

public enum DynamicType: Codable {
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "The container contains an unsupported type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let intValue):
            try container.encode(intValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        case .bool(let boolValue):
            try container.encode(boolValue)
        }
    }
    
    public var intValue: Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }

    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }   
    
}

