//
//  PersistentAppData.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if appdata
import TealiumCore
#endif

public struct PersistentAppData: Codable {

    public let visitorId: String
    public let uuid: String

    public func toDictionary() -> [String: Any] {
        return [TealiumKey.uuid: uuid,
                TealiumKey.visitorId: visitorId]
    }

    public static func initFromDictionary(_ existingData: [String: Any]) -> PersistentAppData? {
        guard let uuid = existingData[TealiumKey.uuid] as? String,
            let visitorId = existingData[TealiumKey.visitorId] as? String else {
                return nil
        }
        return PersistentAppData(visitorId: visitorId, uuid: uuid)
    }
}
