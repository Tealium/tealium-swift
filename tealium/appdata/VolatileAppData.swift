//
//  VolatileAppData.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if appdata
import TealiumCore
#endif

struct VolatileAppData: Codable {
    var name: String?,
        rdns: String?,
        version: String?,
        build: String?,
        persistentData: PersistentAppData?

    public func toDictionary() -> [String: Any] {
        var allData = [String: Any]()
        if let persistentData = persistentData {
            allData += persistentData.toDictionary()
        }

        if let name = name {
            allData[TealiumAppDataKey.name] = name
        }

        if let rdns = rdns {
            allData[TealiumAppDataKey.rdns] = rdns
        }

        if let version = version {
            allData[TealiumAppDataKey.version] = version
        }

        if let build = build {
            allData[TealiumAppDataKey.build] = build
        }

        return allData
    }

    mutating func removeAll() {
        persistentData = nil
        name = nil
        version = nil
        rdns = nil
        build = nil
    }

    var count: Int {
        return self.toDictionary().count
    }
}
