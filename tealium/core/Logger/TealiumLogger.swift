//
//  TealiumLogger.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

/// Internal console logger for library debugging.
public struct TealiumLogger {

    let idString: String
    var logThreshold: TealiumLogLevel

    /// Modules may initialize their own loggers, passing in the log level from the TealiumConfig object￼.
    ///
    /// - Parameters:
    ///     - loggerId: `String` providing a unique name for this logger instance￼
    ///     - logLevel: `TealiumLogLevel` indicating the type of errors that should be logged
    public init(loggerId: String,
                logLevel: TealiumLogLevel) {
        self.idString = loggerId
        self.logThreshold = logLevel
    }

    /// Prints messages to the console￼.
    ///
    /// - Parameters:
    ///     - message: `String` containing the message to be logged￼
    ///     - logLevel: `TealiumLogLevel` indicating the severity of the message to be logged
    @discardableResult
    public func log(message: String,
                    logLevel: TealiumLogLevel) -> String? {
        if logThreshold >= logLevel {
            var verbosity = ""
            if logLevel == .errors { verbosity = "ERROR: " }
            if logLevel == .warnings { verbosity = "WARNING: " }

            print("*** TEALIUM SWIFT \(TealiumValue.libraryVersion) *** Instance \(idString): \(verbosity)\(message)")
            return message
        }
        return nil
    }
}
