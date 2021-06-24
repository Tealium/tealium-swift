//
//  TealiumLogger.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
import os.log

@available(iOS 10.0, tvOS 12.0, macOS 10.12, watchOS 4.0, *)
extension OSLog {
    static let `init`: OSLog = OSLog(subsystem: "com.tealium.swift", category: "init")
    static let track: OSLog = OSLog(subsystem: "com.tealium.swift", category: "track")
    static let general: OSLog = OSLog(subsystem: "com.tealium.swift", category: "general")
}

/// Internal console logger for library debugging.
public class TealiumLogger: TealiumLoggerProtocol {

    var logThreshold: TealiumLogLevel {
        config?.logLevel ?? TealiumValue.defaultLogLevel
    }
    var loggerType: TealiumLoggerType? {
        config?.loggerType ?? .os
    }

    public weak var config: TealiumConfig?

    /// Modules may initialize their own loggers, passing in the log level from the TealiumConfig object￼.
    ///
    /// - Parameters:
    ///     - config: `TealiumConfig` object
    required public init(config: TealiumConfig) {
        self.config = config
    }

    /// Prints messages to the console￼.
    ///
    /// - Parameters:
    ///     - message: `String` containing the message to be logged￼
    ///     - request: `TealiumLogRequest` to log
    public func log(_ request: TealiumLogRequest) {
        switch loggerType {
        case .os:
            if #available(iOS 10.0, tvOS 12.0, macOS 10.12, watchOS 4.0, *) {
                osLog(request)
            } else {
                textLog(request)
            }
        case .print:
            textLog(request)
        default:
            textLog(request)
        }
    }

    // set log level to default to hide info messages xcrun simctl spawn booted log config --mode "level:default" --subsystem com.tealium.swift
    @available(iOS 10.0, tvOS 12.0, macOS 10.12, watchOS 4.0, *)
    func osLog(_ request: LogRequest) {

        guard logThreshold > .silent else {
            return
        }

        let message = request.formattedString
        var logLevel: OSLogType
        switch request.logLevel {
        case .debug:
            logLevel = .debug
        case .info:
            logLevel = .info
        case .error:
            logLevel = .error
        case .fault:
            logLevel = .fault
        default:
            logLevel = .info
        }

        os_log("%{public}@", log: getLogCategory(request: request), type: logLevel, message)
    }

    @available(iOS 10.0, tvOS 12.0, macOS 10.12, watchOS 4.0, *)
    func getLogCategory(request: LogRequest) -> OSLog {
        switch request.logCategory {
        case .general:
            return .general
        case .track:
            return .track
        case .`init`:
            return .`init`
        default:
            return .general
        }
    }

    func textLog(_ request: TealiumLogRequest) {
        guard logThreshold > .silent,
              request.logLevel >= logThreshold else {
            return
        }
        print(request.formattedString)
    }

}
