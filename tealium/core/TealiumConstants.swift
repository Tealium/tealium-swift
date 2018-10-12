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
    static let libraryName = "swift"
    static let libraryVersion = "1.6.4"
}

// MARK: 
// MARK: ENUMS

public enum TealiumKey {
    public static let account = "tealium_account"
    public static let profile = "tealium_profile"
    public static let environment = "tealium_environment"
    public static let event = "tealium_event"
    public static let callType = "call_type"
    public static let screenTitle = "screen_title"
    public static let eventType = "tealium_event_type"
    public static let libraryName = "tealium_library_name"
    public static let libraryVersion = "tealium_library_version"
    public static let queueReason = "queue_reason"
    public static let wasQueued = "was_queued"
    public static let dispatchService = "dispatch_service"
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
