//
//  TealiumLogger.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 tealium. All rights reserved.
//

import Foundation

/**
 Internal console logger for library debugging.
 
 */
public class TealiumLogger {

    let idString: String
    var logThreshold: TealiumLogLevel

    init(loggerId: String, logLevel: TealiumLogLevel) {
        self.idString = loggerId
        self.logThreshold = logLevel
    }

    public func log(message: String, logLevel: TealiumLogLevel) -> String? {
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
