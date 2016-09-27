//
//  tealiumLogger.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

enum LogLevel {
    case none
    case errors
    case warnings
    case verbose
    
    var description : String {
        switch self {
        case .errors:
            return "Errors"
        case .warnings:
            return "Warnings"
        case .verbose:
            return "Verbose"
        default:
            return "None"
        }
    }
    
    static func fromString(_ string: String) -> LogLevel {
        switch string.lowercased() {
        case "errors":
            return .errors
        case "warnings":
            return .warnings
        case "verbose":
            return .verbose
        default:
            return .none
        }
    }
}

/**
    Internal console logger for library debugging.
 
 */
class TealiumLogger {
    
    let idString : String
    var logThreshold : LogLevel
    
    init(loggerId: String, logLevel: LogLevel) {
        
        self.idString = loggerId
        self.logThreshold = logLevel
        
    }
    
    class func logNSError(_ error:NSError) {
        print("\(error.localizedDescription)")
    }
    
    func log( _ message: String, logLevel: LogLevel) -> String? {

        if logThreshold.hashValue >= logLevel.hashValue {
            print("Tealium instance \(idString): \(message)")
            return message
        }
        return nil
    }
    
}
