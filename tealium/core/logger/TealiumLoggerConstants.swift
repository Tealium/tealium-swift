//
//  TealiumLoggerConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumValue {
    static let defaultLogLevel = TealiumLogLevel.error
}

public enum TealiumLogLevel: Int, Comparable, CustomStringConvertible {

    case info = 0
    case debug = 100
    case error = 200
    case fault = 300
    case silent = -9999

    public init(from string: String) {
        switch string {
        case "info":
            self = .info
        case "debug":
            self = .debug
        case "error":
            self = .error
        case "fault":
            self = .fault
        case "none":
            self = .silent
        default:
            self = .silent
        }
    }

    public var description: String {
        switch self {
        case .info:
            return "Info"
        case .debug:
            return "Debug"
        case .error:
            return "Error"
        case .fault:
            return "Fault"
        case .silent:
            return "Silent"
        }
    }

    public static func < (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// swiftlint:disable identifier_name
public enum TealiumLoggerType {
    case print
    case os
    case custom(TealiumLoggerProtocol)
}
// swiftlint:enable identifier_name
