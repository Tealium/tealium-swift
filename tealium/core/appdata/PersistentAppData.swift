//
//  PersistentAppData.swift
//  TealiumSwift
//
//  Created by Craig Rouse on 28/11/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public struct PersistentAppData: Codable {

    public let visitorId: String
    public let uuid: String

    public var dictionary: [String: Any] {
        [TealiumKey.uuid: uuid,
         TealiumKey.visitorId: visitorId]
    }

    public static func new(from existingData: [String: Any]) -> PersistentAppData? {
        guard let uuid = existingData[TealiumKey.uuid] as? String,
            let visitorId = existingData[TealiumKey.visitorId] as? String else {
                return nil
        }
        return PersistentAppData(visitorId: visitorId, uuid: uuid)
    }
}
