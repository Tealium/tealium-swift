//
//  TealiumConstants.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

// MARK: VALUES

public enum TealiumValue {
    public static let libraryName = "swift"
    public static let libraryVersion = "1.8.2"
    // This is the current limit for performance reasons. May be increased in future
    public static let maxEventBatchSize = 10
    public static let defaultMinimumDiskSpace: Int32 = 20_000_000
}

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
    public static let updateConsentCookieEventName = "update_consent_cookie"
    public static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
    public static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
    public static let jsCommand = "js"
    public static let traceId = "cp.trace_id"
    public static let killVisitorSession = "kill_visitor_session"
    // used for remote commands
    public static let tealiumURLScheme = "tealium"
    public static let dataSource = "tealium_datasource"
    public static let sessionId = "tealium_session_id"
    public static let visitorId = "tealium_visitor_id"
    public static let random = "tealium_random"
    public static let uuid = "app_uuid"
    public static let simpleModel = "model_name" // e.g. iPhone 5s // OLD: device
    public static let device = "device" // == model_name
    public static let deviceType = "device_type"
    public static let fullModel = "model_variant" // e.g. CDMA, GSM
    public static let architectureLegacy = "cpu_architecture"
    public static let architecture = "device_architecture"
    public static let cpuTypeLegacy = "cpu_type"
    public static let cpuType = "device_cputype"
    public static let languageLegacy = "user_locale"
    public static let language = "device_language"
    public static let osName = "os_name"
    public static let platform = "platform"
    public static let resolution = "device_resolution"
    public static let minimumFreeDiskSpace = "min_free_disk_space"
    public static let diskStorageEnabled = "disk_storage"
    public static let logLevelConfig = "com.tealium.logger.loglevel"
    public static let timestampUnix = "timestamp_unix"
    public static let timestampUnixMilliseconds = "timestamp_unix_milliseconds"
    public static let prod = "prod"
    public static let dev = "dev"
    // swiftlint:disable identifier_name
    public static let qa = "qa"
    // swiftlint:enable identifier_name
    public static let errorHeaderKey = "X-Error"
    public static let diskStorageDirectory = "disk_storage_directory"
    public static let remoteAPICallType = "remote_api"
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

// MARK: STRUCTS

/// White or black list of module names to enable. TealiumConfig can be set
///     with this list which will be read by internal components to determine
///     which modules to spin up, if they are included with the existing build.
public struct TealiumModulesList: Equatable {
    public let isWhitelist: Bool
    public let moduleNames: Set<String>

    public init(isWhitelist: Bool,
                moduleNames: Set<String>) {
        self.isWhitelist = isWhitelist
        self.moduleNames = Set(moduleNames.map {
            $0.lowercased()
        })
    }
}

// MARK: TYPEALIASES

public typealias TealiumCompletion = ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)
