//
//  AppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

struct AppData: Codable {
    var name: String?,
        rdns: String?,
        version: String?,
        build: String?,
        persistentData: PersistentAppData?

    public var dictionary: [String: Any] {
        var allData = [String: Any]()
        if let persistentData = persistentData {
            allData += persistentData.dictionary
        }

        if let name = name {
            allData[TealiumKey.appName] = name
        }

        if let rdns = rdns {
            allData[TealiumKey.appRDNS] = rdns
        }

        if let version = version {
            allData[TealiumKey.appVersion] = version
        }

        if let build = build {
            allData[TealiumKey.appBuild] = build
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
        return self.dictionary.count
    }
}
