//
//  ConnectivityConfigExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    /// Sets the interval with which new connectivity checks will be carried out.
    var connectivityRefreshInterval: Int? {
        get {
            options[ConnectivityKey.refreshIntervalKey] as? Int
        }

        set {
            options[ConnectivityKey.refreshIntervalKey] = newValue
        }
    }

    /// Determines if connectivity status checks should be carried out automatically.
    /// If `true` (default), queued track calls will be flushed when connectivity is restored.
    var connectivityRefreshEnabled: Bool? {
        get {
            options[ConnectivityKey.refreshEnabledKey] as? Bool
        }

        set {
            options[ConnectivityKey.refreshEnabledKey] = newValue
        }
    }
}

public extension Collectors {
    static let Connectivity = ConnectivityModule.self
}
