//
//  TealiumLoggerConstants.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

enum TealiumLoggerKey {
    static let moduleName = "logger"
}

public enum TealiumLogLevelValue {
    static let errors = "errors"
    static let none = "none"
    static let verbose = "verbose"
    static let warnings = "warnings"
}

public enum TealiumLoggerModuleError : Error {
    
    case moduleDisabled
    case noAccount
    case noProfile
    case noEnvironment
    
}

public enum LogLevel {
    case none
    case errors
    case warnings
    case verbose
    
    var description : String {
        switch self {
        case .errors:
            return TealiumLogLevelValue.errors
        case .warnings:
            return TealiumLogLevelValue.warnings
        case .verbose:
            return TealiumLogLevelValue.verbose
        default:
            return TealiumLogLevelValue.none
        }
    }
    
    static func fromString(_ string: String) -> LogLevel {
        switch string.lowercased() {
        case TealiumLogLevelValue.errors:
            return .errors
        case TealiumLogLevelValue.warnings:
            return .warnings
        case TealiumLogLevelValue.verbose:
            return .verbose
        default:
            return .none
        }
    }
}
