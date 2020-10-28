//
//  ConnectivityConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum ConnectivityConstants {
    static let defaultInterval: Int = 30
    static let connectivityTestURL = "https://tags.tiqcdn.com"
}

enum ConnectivityKey {
    static let moduleName = "connectivity"
    static let connectionType = "connection_type"
    static let connectionTypeWifi = "wifi"
    static let connectionTypeWired = "wired"
    static let connectionTypeCell = "cellular"
    static let connectionTypeNone = "none"
    static let refreshIntervalKey = "refresh_interval"
    static let refreshEnabledKey = "refresh_enabled"
}
