//
//  DataLayerCollection.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Set where Element == DataLayerItem {

    /// Inserts a new `DataLayerItem` into the `Set<DataLayerItem>` store
    /// If a value for that key already exists, it will be removed before
    /// the new value is inserted.
    /// - Parameters:
    ///   - dictionary: `[String: Any]` values being inserted into the `Set<DataLayerItem>` store
    ///   - expires: `Date` expiration date
    mutating func insert(from dictionary: [String: Any], expiry: Expiry) {
        dictionary.forEach { item in
            if let existing = self.first(where: { value -> Bool in
                value.key == item.key
            }) {
                self.remove(existing)
            }
            let eventDataValue = DataLayerItem(key: item.key, value: item.value, expiry: expiry)
            self.insert(eventDataValue)
        }
    }

    /// Inserts a new `DataLayerItem` into the `Set<DataLayerItem>` store
    /// If a value for that key already exists, it will be removed before
    /// the new value is inserted.
    /// - Parameters:
    ///   - key: `String` name for the value
    ///   - value: `Any` should be `String` or `[String]`
    ///   - expires: `Date` expiration date
    mutating func insert(key: String, value: Any, expiry: Expiry) {
        self.insert(from: [key: value], expiry: expiry)
    }

    /// Removes the `DataLayerItem` from the `EventData` store
    /// - Parameter key: `String` name of key to remove
    mutating func remove(key: String) {
        self.filter {
            $0.key == key
        }.forEach {
            self.remove($0)
        }
    }

    /// Removes expired data from the `Set<DataLayerItem>` store
    /// - Returns: `Set<DataLayerItem>` after removal
    func removeExpired() -> Set<DataLayerItem> {
        let currentDate = Date()
        let newDataLayer = self.filter {
            $0.expires > currentDate || $0.isSession
        }
        return newDataLayer
    }

    mutating func removeSessionData() {
        let sessionData = self.filter { $0.isSession }
        for key in sessionData.map({ $0.key }) {
            self.remove(key: key)
        }
    }

    /// - Returns: `[String: Any]` all the data currently in the `Set<DataLayerItem>` store
    var all: [String: Any] {
        var returnData = [String: Any]()
        self.forEach { eventDataItem in
            returnData[eventDataItem.key] = eventDataItem.value
        }
        return returnData
    }

}

public struct DataLayerItem: Codable, Hashable {
    public static func == (lhs: DataLayerItem, rhs: DataLayerItem) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    var key: String
    var value: Any
    var expires: Date
    var isSession: Bool

    enum CodingKeys: String, CodingKey {
        case key
        case value
        case expires
        case isSession
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(AnyCodable(value), forKey: .value)
        try container.encode(expires, forKey: .expires)
        try container.encode(isSession, forKey: .isSession)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try values.decode(AnyCodable.self, forKey: .value)
        value = decoded.value
        expires = try values.decode(Date.self, forKey: .expires)
        key = try values.decode(String.self, forKey: .key)
        isSession = try values.decodeIfPresent(Bool.self, forKey: .isSession) ?? false // values added by previous version may not have isSession in the storage the first time they launched after the update from version <= 2.4.5
    }

    public init(key: String,
                value: Any,
                expiry: Expiry) {
        self.key = key
        self.value = value
        self.expires = expiry.date
        self.isSession = expiry.isSession()
    }
}
