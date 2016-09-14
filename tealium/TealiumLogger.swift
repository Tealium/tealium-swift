//
//  tealiumLogger.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

enum LogLevel {
    case None
    case Errors
    case Warnings
    case Verbose
    
    var description : String {
        switch self {
        case .Errors:
            return "Errors"
        case .Warnings:
            return "Warnings"
        case .Verbose:
            return "Verbose"
        default:
            return "None"
        }
    }
    
    static func fromString(string: String) -> LogLevel {
        switch string.lowercaseString {
        case "errors":
            return .Errors
        case "warnings":
            return .Warnings
        case "verbose":
            return .Verbose
        default:
            return .None
        }
    }
}

class TealiumLogger {
    
    let idString : String
    var logThreshold : LogLevel
    
    init(loggerId: String, logLevel: LogLevel) {
        
        self.idString = loggerId
        self.logThreshold = logLevel
        
    }
    
    class func logNSError(error:NSError) {
        print("\(error.localizedDescription)")
    }
    
    func log( message: String, logLevel: LogLevel) -> String? {

        if logThreshold.hashValue >= logLevel.hashValue {
            print("Tealium instance \(idString): \(message)")
            return message
        }
        return nil
    }
    
}