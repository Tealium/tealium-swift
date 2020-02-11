//
//  TealiumConnectivityConfigExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if connectivity
import TealiumCore
#endif

public extension TealiumConfig {

    /// Sets the interval with which new connectivity checks will be carried out.
    ///￼
    /// - Parameter interval: `Int` representing the number of seconds between connectivity checks (default 30s)
    @available(*, deprecated, message: "Please switch to config.connectivityRefreshInterval")
    func setConnectivityRefreshInterval(_ interval: Int) {
        connectivityRefreshInterval = interval
    }

    /// Sets the interval with which new connectivity checks will be carried out.
    var connectivityRefreshInterval: Int? {
        get {
            optionalData[TealiumConnectivityKey.refreshIntervalKey] as? Int
        }

        set {
            optionalData[TealiumConnectivityKey.refreshIntervalKey] = newValue
        }
    }

    /// Determines if connectivity status checks should be carried out automatically.
    /// If `true` (default), queued track calls will be flushed when connectivity is restored.
    ///￼
    /// - Parameter enabled: `Bool` (default `true` - set to `false` if needing to disable this functionality)
    @available(*, deprecated, message: "Please switch to config.connectivityRefreshEnabled")
    func setConnectivityRefreshEnabled(_ enabled: Bool) {
        connectivityRefreshEnabled = enabled
    }

    /// Determines if connectivity status checks should be carried out automatically.
    /// If `true` (default), queued track calls will be flushed when connectivity is restored.
    var connectivityRefreshEnabled: Bool? {
        get {
            optionalData[TealiumConnectivityKey.refreshEnabledKey] as? Bool
        }

        set {
            optionalData[TealiumConnectivityKey.refreshEnabledKey] = newValue
        }
    }
}
