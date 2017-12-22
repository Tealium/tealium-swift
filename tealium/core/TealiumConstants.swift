//
//  TealiumConstants.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//
//  Build 3


// MARK: VALUES

public enum TealiumValue {
    static let libraryName = "swift"
    static let libraryVersion = "1.4.0"
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

public enum TealiumModulesManagerError : Error {
    case isDisabled
    case noModules
    case noModuleConfigs
    case duplicateModuleConfigs
}

public enum TealiumModuleError : Error {
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

/// Feedback from modules for internal requests (such as an enabling).
public struct TealiumModuleResponse {
    public let moduleName: String
    public let success: Bool
    public var info: [String:Any]?
    public var error: Error?
    
    init(moduleName: String,
         success: Bool,
         error: Error?) {
        self.moduleName = moduleName
        self.success = success
        self.error = error
        self.info = nil
    }
}

// MARK:
// MARK: REQUEST TYPES

// Requests are internal notification types used between the modules and
//  modules manager to enable, disable, load, save, delete, and process
//  track data. All request types most conform to the TealiumRequest protocol.
//  The module base class will respond by default to enable, disable, and track
//  but sub classes are expected to override these and/or implement handling of
//  any of the following additional requests or to a module's own custom request
//  type.


/// Request protocol
public protocol TealiumRequest {
    var typeId : String { get set }
    var moduleResponses : [TealiumModuleResponse] { get set }
    var completion: TealiumCompletion? { get set }
    static func instanceTypeId() -> String
}


/// Request to delete persistent data
public struct TealiumDeleteRequest: TealiumRequest {
    public var typeId = TealiumDeleteRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    let name: String
    
    init(name: String){
        self.name = name
        self.completion = nil
    }
    
    public static func instanceTypeId() -> String {
        return "delete"
    }
}


/// Request to disable.
public struct TealiumDisableRequest: TealiumRequest {
    public var typeId = TealiumDisableRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    public static func instanceTypeId() -> String {
        return "disable"
    }
}


/// Request to enable.
public struct TealiumEnableRequest : TealiumRequest {
    public var typeId = TealiumEnableRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    let config: TealiumConfig
    
    init(config: TealiumConfig){
        self.config = config
    }
    
    public static func instanceTypeId() -> String {
        return "enable"
    }
}


/// Request to load persistent data.
public struct TealiumLoadRequest : TealiumRequest {
    public var typeId = TealiumLoadRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    let name: String
    
    init(name: String,
         completion: TealiumCompletion?) {
        self.name = name
        self.completion = completion
    }
    
    public static func instanceTypeId() -> String {
        return "load"
    }
}

// Module wants to report status to any listening modules
public struct TealiumReportRequest : TealiumRequest {
    public var typeId = TealiumReportNotificationsRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    let message: String
    
    init(message: String) {
        self.message = message
    }
    
    public static func instanceTypeId() -> String {
        return "report"
    }
}

// Module requests to be notified of any reports or when all modules finished
//  processing a request.
public struct TealiumReportNotificationsRequest : TealiumRequest {
    public var typeId = TealiumReportNotificationsRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    public static func instanceTypeId() -> String {
        return "reportnotification"
    }
}


/// Request to send any queued data.
public struct TealiumReleaseQueuesRequest : TealiumRequest {
    public var typeId = TealiumSaveRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    public static func instanceTypeId() -> String {
        return "queuerelease"
    }
}


/// Request to save persistent data.
public struct TealiumSaveRequest : TealiumRequest {
    public var typeId = TealiumSaveRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    let name: String
    let data: [String:Any]
    
    init(name: String,
         data: [String:Any]){
        self.name = name
        self.data = data
        self.completion = nil
    }
    
    public static func instanceTypeId() -> String {
        return "save"
    }
}


/// Request to deliver data.
public struct TealiumTrackRequest : TealiumRequest {
    public var typeId = TealiumTrackRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    
    let data: [String:Any]
//    var info: [String:Any]?
    
    init(data: [String:Any],
         completion: TealiumCompletion?) {
        self.data = data
        self.completion = completion
        
    }
    
//    init(data: [String:Any],
//         info: [String:Any]?,
//         completion: TealiumCompletion?){
//        self.data = data
//        self.info = info
//        self.completion = completion
//    }
    
    public static func instanceTypeId() -> String {
        return "track"
    }
}

// MARK:
// MARK: TYPEALIASES

public typealias TealiumCompletion = ((_ successful: Bool, _ info: [String:Any]?, _ error: Error?)-> Void)


