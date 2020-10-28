//
//  TealiumLoggerExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {

    var logger: TealiumLoggerProtocol? {
        zz_internal_modulesManager?.logger
    }
}

public extension TealiumConfig {
    /// Sets the logger type. Defaults to os_log on iOS 10+
    var loggerType: TealiumLoggerType {
        get {
            options[TealiumKey.loggerType] as? TealiumLoggerType ?? TealiumValue.defaultLoggerType
        }

        set {
            options[TealiumKey.loggerType] = newValue
        }
    }

    /// Sets the log level
    var logLevel: TealiumLogLevel? {
        get {
            options[TealiumKey.logLevel] as? TealiumLogLevel
        }

        set {
            options[TealiumKey.logLevel] = newValue
        }
    }

}
