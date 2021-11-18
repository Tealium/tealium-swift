//
//  ConnectivityConfigExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumConfigKey {
    static let refreshIntervalKey = "refresh_interval"
    static let refreshEnabledKey = "refresh_enabled"
}

public extension TealiumConfig {

    /// Sets the interval with which new connectivity checks will be carried out.
    var connectivityRefreshInterval: Int? {
        get {
            options[TealiumConfigKey.refreshIntervalKey] as? Int
        }

        set {
            options[TealiumConfigKey.refreshIntervalKey] = newValue
        }
    }

    /// Determines if connectivity status checks should be carried out automatically.
    /// If `true` (default), queued track calls will be flushed when connectivity is restored.
    var connectivityRefreshEnabled: Bool? {
        get {
            options[TealiumConfigKey.refreshEnabledKey] as? Bool
        }

        set {
            options[TealiumConfigKey.refreshEnabledKey] = newValue
        }
    }
}

public extension Collectors {
    static let Connectivity = ConnectivityModule.self
}
