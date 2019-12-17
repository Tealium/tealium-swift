//
//  TealiumLoggerConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/07/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumLogLevelValue {
    static let errors = "errors"
    static let none = "none"
    static let verbose = "verbose"
    static let warnings = "warnings"
}

public let defaultTealiumLogLevel: TealiumLogLevel = .errors

public enum TealiumLogLevel: Int, Comparable {
    case none = 0
    case errors = 1
    case warnings = 2
    case verbose = 3

    var description: String {
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

    static func fromString(_ string: String) -> TealiumLogLevel {
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

    public static func < (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func > (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }

    public static func <= (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func >= (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
}
