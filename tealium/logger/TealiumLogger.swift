//
//  tealiumLogger.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

/**
    Internal console logger for library debugging.
 
 */
public class TealiumLogger {
    
    let idString : String
    var logThreshold : LogLevel
    
    init(loggerId: String, logLevel: LogLevel) {
        
        self.idString = loggerId
        self.logThreshold = logLevel
        
    }
    
    public func log(message: String, logLevel: LogLevel) -> String? {

        if logThreshold.hashValue >= logLevel.hashValue {
            var verbosity = ""
            if logLevel == .errors { verbosity = "ERROR: "}
            if logLevel == .warnings { verbosity = "WARNING: "}
            
            print("*** TEALIUM SWIFT \(TealiumValue.libraryVersion) *** Instance \(idString): \(verbosity)\(message)")
            return message
        }
        return nil
    }
    
}
