//
//  PersistentAppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public struct PersistentAppData: Codable {

    public var visitorId: String
    public var uuid: String

    public var dictionary: [String: Any] {
        [TealiumDataKey.uuid: uuid,
         TealiumDataKey.visitorId: visitorId]
    }

    public static func new(from existingData: [String: Any]) -> PersistentAppData? {
        guard let uuid = existingData[TealiumDataKey.uuid] as? String,
              let visitorId = existingData[TealiumDataKey.visitorId] as? String else {
            return nil
        }
        return PersistentAppData(visitorId: visitorId, uuid: uuid)
    }
}
