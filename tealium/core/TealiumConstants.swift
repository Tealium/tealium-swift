//
//  TealiumConstants.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
//  Build 3

// MARK: VALUES

public enum TealiumValue {
    public static let libraryName = "swift"
    public static let libraryVersion = "1.5.0"
}

// MARK: 
// MARK: ENUMS

public enum TealiumKey {
    static let account = "tealium_account"
    static let profile = "tealium_profile"
    static let environment = "tealium_environment"
    static let event = "tealium_event"
    static let callType = "call_type"
    static let screenTitle = "screen_title"
    static let eventType = "tealium_event_type"
    static let libraryName = "tealium_library_name"
    static let libraryVersion = "tealium_library_version"
}

public enum TealiumModulesManagerError: Error {
    case isDisabled
    case noModules
    case noModuleConfigs
    case duplicateModuleConfigs
}

public enum TealiumModuleError: Error {
    case failedToEnable
    case failedToDisable
    case failedToTrack
    case missingConfigData
    case missingTrackData
    case isDisabled
}

// NOTE: These will be deprecated in a future release.
public enum TealiumTrackType {
    case view           // Whenever content is displayed to the user.
    case event

    func description() -> String {
        switch self {
        case .view:
            return "view"
        case .event:
            return "event"
        }
    }

}

// MARK: 
// MARK: STRUCTS

/// White or black list of module names to enable. TealiumConfig can be set
///     with this list which will be read by internal components to determine
///     which modules to spin up, if they are included with the existing build.
public struct TealiumModulesList {
    public let isWhitelist: Bool
    public let moduleNames: Set<String>

    public init(isWhitelist: Bool,
                moduleNames: Set<String>) {
        self.isWhitelist = isWhitelist
        self.moduleNames = moduleNames
    }
}

// MARK: 
// MARK: TYPEALIASES

public typealias TealiumCompletion = ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)
