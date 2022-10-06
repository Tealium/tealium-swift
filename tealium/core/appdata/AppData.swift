//
//  AppData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

struct AppData {
    var name: String?,
        rdns: String?,
        version: String?,
        build: String?

    public var dictionary: [String: Any] {
        var allData = [String: Any]()

        if let name = name {
            allData[TealiumDataKey.appName] = name
        }

        if let rdns = rdns {
            allData[TealiumDataKey.appRDNS] = rdns
        }

        if let version = version {
            allData[TealiumDataKey.appVersion] = version
        }

        if let build = build {
            allData[TealiumDataKey.appBuild] = build
        }

        return allData
    }

    mutating func removeAll() {
        name = nil
        version = nil
        rdns = nil
        build = nil
    }

    var count: Int {
        return self.dictionary.count
    }
}
