//
//  HostedDataLayerCache.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

struct HostedDataLayerCacheItem: Codable, Equatable {
    static func == (lhs: HostedDataLayerCacheItem, rhs: HostedDataLayerCacheItem) -> Bool {
        if let lhsData = lhs.data, let rhsData = rhs.data {
            return lhs.id == rhs.id && lhsData == rhsData
        } else {
            return lhs.id == rhs.id
        }
    }

    var id: String
    var data: [String: Any]?
    var retrievalDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case data
        case retrievalDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let data = self.data?.encodable {
            try container.encode(id, forKey: .id)
            try container.encode(data, forKey: .data)
            try container.encode(retrievalDate, forKey: .retrievalDate)
        }
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(String.self, forKey: .id)
        if let cacheItem = try values.decode(AnyDecodable.self, forKey: .data).value as? [String: Any] {
            self.id = id
            self.data = cacheItem
            self.retrievalDate = try values.decode(Date?.self, forKey: .retrievalDate) ?? Date()
        } else {
            throw HostedDataLayerError.unableToDecodeData
        }
    }

    init(id: String,
         data: [String: Any],
         retrievalDate: Date = Date()) {
        self.id = id
        self.data = data
        self.retrievalDate = retrievalDate
    }
}

extension Array where Element == HostedDataLayerCacheItem {
    internal subscript(_ id: String) -> [String: Any]? {
        self.first { $0.id == id }?.data
    }
}
