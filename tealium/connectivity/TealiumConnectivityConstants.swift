//
//  TealiumConnectivityConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumConnectivityConstants {
    public static let defaultInterval: Int = 30
}

enum TealiumConnectivityKey {
    static let moduleName = "connectivity"
    static let connectionTypeLegacy = "network_connection_type"
    static let connectionType = "connection_type"
    static let connectionTypeWifi = "wifi"
    static let connectionTypeCell = "cellular"
    static let connectionTypeNone = "none"
    static let refreshIntervalKey = "refresh_interval"
    static let refreshEnabledKey = "refresh_enabled"
}
