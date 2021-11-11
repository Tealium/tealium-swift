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
            options[TealiumConfigKey.loggerType] as? TealiumLoggerType ?? TealiumValue.defaultLoggerType
        }

        set {
            options[TealiumConfigKey.loggerType] = newValue
            logger = getNewLogger()
        }
    }

    /// Sets the log level
    var logLevel: TealiumLogLevel? {
        get {
            options[TealiumConfigKey.logLevel] as? TealiumLogLevel
        }

        set {
            options[TealiumConfigKey.logLevel] = newValue
        }
    }

}
