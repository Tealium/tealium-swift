//
//  TealiumConstants.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

public enum TealiumKey {
    static let account = "tealium_account"
    static let profile = "tealium_profile"
    static let environment = "tealium_environment"
    static let eventName = "event_name"     // deprecating
    static let event = "tealium_event"
    static let eventType = "tealium_event_type"
    static let libraryName = "tealium_library_name"
    static let libraryVersion = "tealium_library_version"
}

public enum TealiumModulesManagerError : Error {
    case isDisabled
    case noModules
    case noModuleConfigs
    case duplicateModuleConfigs
}

public enum TealiumModuleConfigKey {
    static let all = "com.tealium.module.configs"
    static let enable = "config_enable"
    static let name = "config_name"
    static let className = "config_class_name"
    static let priority = "config_priority"
}

public enum TealiumModuleError : Error {
    case failedToEnable
    case failedToDisable
    case failedToTrack
    case missingConfigData
    case missingTrackData
}

public enum TealiumModuleProcessType {
    case enable
    case disable
    case track
}

public enum TealiumValue {
    static let libraryName = "swift"
    static let libraryVersion = "1.2.0"
}

public enum TealiumTrackType {
    case view           // Whenever content is displayed to the user.
    case activity       // Behavioral actions by the user such as a cart actions, or any other application-specific event.
    case interaction    // Interaction between user and an external resource (ie other people). Usually offline activities such as a booth visit or phone call, but can be text sent to an online chat agent.
    case derived        // Inferred user data or somehow provided without direct action by user, such as demographics, predictive data, campaign value relations, etc.
    case conversion     // Desired goal has been reached.
    
    func description() -> String {
        switch self {
        case .view:
            return "view"
        case .interaction:
            return "interaction"
        case .derived:
            return "derived"
        case .conversion:
            return "conversion"
        default:
            return "activity"
        }
    }
    
}

public typealias tealiumTrackCompletion = ((_ successful: Bool, _ info: [String:Any]?, _ error: Error?)-> Void)

public struct TealiumTrack {
    var data: [String:Any]
    var info: [String:Any]?
    var completion: tealiumTrackCompletion?
}

public struct TealiumProcess {
    let type: TealiumModuleProcessType
    var successful: Bool
    var track: TealiumTrack?
    var error: Error?
}

