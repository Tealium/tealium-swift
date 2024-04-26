//
//  EngineResponse.swift
//  TealiumMoments
//
//  Created by Craig Rouse on 18/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct EngineResponse: Codable {
    /// The complete set of attributes. Types must be inferred, as the original JSON response is a heterogenous object
    public var attributes: [String: DynamicType] = [:]
    /// The complete list of audiences the visitor is currently assigned to. Could be the audience name, or just the ID, depending on the options specified in the UI.
    public var audiences: [String] = []
    /// The complete list of badges assigned to the visitor.. Could be the badge name, or just the ID, depending on the options specified in the UI.
    public var badges: [String] = []
    
    /// All audiencestream `String` attributes currently assigned to the visitor
    public var strings: [String] {
        attributes.compactMap {
            $0.value.stringValue
        }
    }
    
    /// All audiencestream `Boolean` attributes currently assigned to the visitor
    public var booleans: [String: Bool] {
        attributes.reduce(into: [String: Bool]()) { result, attribute in
            if let boolValue = attribute.value.boolValue {
                result[attribute.key] = boolValue
            }
        }
    }
    
    /// All audiencestream `Date` attributes currently assigned to the visitor, which are millisecond-precise Unix timestamps
    public var dates: [String: Int]  {
        attributes.reduce(into: [String: Int]()) { result, attribute in
            if let doubleValue = attribute.value.doubleValue {
                let intValue = Int(doubleValue)
                
                // This will also catch integers of 13 digits which are not millisecond timestamps,
                // but the chances of encountering such a value are infinitesimally small in Tealium
                if String(intValue).count == 13  {
                    result[attribute.key] = intValue
                }
            }
        }
    }
    
    /// All audiencestream `Number` attributes currently assigned to the visitor
    public var numbers: [String: Double] {
        attributes.reduce(into: [String: Double]()) { result, attribute in
            if let doubleValue = attribute.value.doubleValue {
                let intValue = Int(doubleValue)
                
                if String(intValue).count != 13 {
                    result[attribute.key] = doubleValue
                }
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        // allows for the properties object to be updated to another keyname later, which may happen to disambiguate string properties from general attributes
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
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        }  else if let stringValue = try? container.decode(String.self) {
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

    // number types in AudienceStream should always be floating point numbers
    public var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    // this should represent the AudienceStream String attribute
    public var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    // this should represent the AudienceStream Boolean attribute
    public var boolValue: Bool? {
        if case .bool(let value) = self {
            return value
        }
        return nil
    }   
    
}

