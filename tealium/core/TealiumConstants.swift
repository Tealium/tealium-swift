//
//  TealiumConstants.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: VALUES
public enum Collectors {}

public enum Dispatchers {}

public enum TealiumValue {
    public static let libraryName = "swift"
    public static let libraryVersion = "2.18.0"
    // This is the current limit for performance reasons. May be increased in future
    public static let maxEventBatchSize = 10
    public static let defaultMinimumDiskSpace: Int32 = 20_000_000
    public static let tealiumDleBaseURL = "https://tags.tiqcdn.com/dle/"
    public static let tiqBaseURL = "https://tags.tiqcdn.com/utag/"
    public static let tiqURLSuffix = "mobile.html?sdk_session_count=true"
    public static let defaultBatchExpirationDays = 7
    public static let defaultMaxQueueSize = 40
    static let defaultLoggerType: TealiumLoggerType = .os
    static let connectionRestoredReason = "Connection Restored"
    static let hdlMaxRetries = 3
    static let hdlCacheSizeMax = 50
    static let defaultHDLExpiry: (Int, unit: TimeUnit) = (7, unit: .days)
    static let mobile = "mobile"
    public static let unknown = "unknown"
    public static let timedEvent = "timed_event"
}

public enum ModuleNames {
    public static let autotracking = "AutoTracking"
    public static let appdata = "AppData"
    public static let attribution = "Attribution"
    public static let collect = "Collect"
    public static let connectivity = "Connectivity"
    public static let consentmanager = "ConsentManager"
    public static let crash = "Crash"
    public static let devicedata = "DeviceData"
    public static let lifecycle = "Lifecycle"
    public static let inapppurchase = "InAppPurchase"
    public static let location = "Location"
    public static let momentsapi = "MomentsAPI"
    public static let remotecommands = "RemoteCommands"
    public static let tagmanagement = "TagManagement"
    public static let visitorservice = "VisitorService"
}

public enum TealiumDataKey {
}

public extension TealiumDataKey {
    static let account = "tealium_account"
    static let profile = "tealium_profile"
    static let environment = "tealium_environment"
    static let visitorId = "tealium_visitor_id"
    static let origin = "origin"
    static let event = "tealium_event"
    static let screenTitle = "screen_title"
    static let eventType = "tealium_event_type"
    static let libraryName = "tealium_library_name"
    static let libraryVersion = "tealium_library_version"
    static let queueReason = "queue_reason"
    static let wasQueued = "was_queued"
    static let dispatchService = "dispatch_service"
    static let dataSource = "tealium_datasource"
    static let sessionId = "tealium_session_id"
    static let random = "tealium_random"
    static let uuid = "app_uuid"
    static let requestUUID = "request_uuid"
    static let simpleModel = "model_name" // e.g. iPhone 5s // OLD: device
    static let device = "device" // == model_name
    static let deviceType = "device_type"
    static let fullModel = "model_variant" // e.g. CDMA, GSM
    static let architecture = "device_architecture"
    static let cpuType = "device_cputype"
    static let language = "device_language"
    static let osName = "os_name"
    static let platform = "platform"
    static let resolution = "device_resolution"
    static let logicalResolution = "device_logical_resolution"
    static let enabledModules = "enabled_modules"
    static let deepLinkURL = "deep_link_url"
    static let deepLinkQueryPrefix = "deep_link_param"
    static let deepLinkReferrerUrl = "deep_link_referrer_url"
    static let deepLinkReferrerApp = "deep_link_referrer_app"
    static let killVisitorSessionEvent = "event"
    static let traceId = "cp.trace_id"
    static let timedEventName = "timed_event_name"
    static let eventStart = "timed_event_start"
    static let eventStop = "timed_event_end"
    static let eventDuration = "timed_event_duration"
    static let timestampUnix = "timestamp_unix"
    static let timestampUnixMilliseconds = "timestamp_unix_milliseconds"
    static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
}

public enum TealiumConfigKey {
    public static let publishSettings = "remote_publish_settings"
    public static let publishSettingsURL = "publish_settings_url"
    public static let publishSettingsProfile = "publish_settings_profile"
    static let visitorId = "tealium_visitor_id"
    public static let libraryEnabled = "library_is_enabled"
    public static let batterySaver = "battery_saver"
    public static let queueSizeKey = "queue_size"
    static let appDelegateProxy = "app_delegate_proxy"
    static let skAdConversionKeys = "attribution_conversion_keys"
    static let hostedDataLayerKeys = "hosted_data_layer_keys"
    static let hostedDataLayerExpiry = "hosted_data_layer_expiry"
    static let consentExpiry = "consent_expiry"
    static let consentExpiryCallback = "consent_expiry_callback"
    static let overrideConsentCategoriesKey = "override_consent_categories_key"
    static let timedEventTriggers = "timed_event_triggers"
    // number of events in a batch, max 10
    public static let batchSizeKey = "batch_size"
    // max stored events (e.g. if offline) to limit disk space consumed
    public static let eventLimit = "event_limit"
    public static let batchingEnabled = "batching_enabled"
    public static let batchExpirationDaysKey = "batch_expiration_days"
    public static let wifiOnlyKey = "wifi_only_sending"
    public static let minutesBetweenRefresh = "minutes_between_refresh"
    public static let collectModuleName = "collect"
    public static let tagManagementModuleName = "tagmanagement"
    public static let loggerType = "logger_type"
    public static let logLevel = "log_level"
    public static let logger = "com.tealium.logger"
    public static let dispatchValidators = "dispatch_validators"
    public static let dispatchListeners = "dispatch_listeners"
    public static let collectors = "collectors"
    public static let dispatchers = "dispatchers"
    static let lifecycleAutotrackingEnabled = "enable_lifecycle_autotracking"
    static let deepLinkTrackingEnabled = "deep_link_tracking_enabled"
    static let sendDeepLinkEvent = "send_deep_link_event"
    static let qrTraceEnabled = "qr_trace_enabled"
    static let shouldMigrate = "should_migrate_data"
    public static let enableBackgroundMedia = "enable_background_media_tracking"
    public static let autoEndSesssionTime = "media_auto_end_session_time"
    static let minimumFreeDiskSpace = "min_free_disk_space"
    static let diskStorageEnabled = "disk_storage"
    public static let diskStorageDirectory = "disk_storage_directory"
    public static let sessionCountingEnabled = "session_counting_enabled"
}

public enum TealiumKey {

    public static let updateConsentCookieEventNames = ["update_consent_cookie", "set_dns_state"]
    public static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
    public static let jsCommand = "js"
    // used for remote commands
    public static let persistentData = "persistentData"
    public static let persistentVisitorId = "visitorId"
    public static let logLevelConfig = "com.tealium.logger.loglevel"
    public static let prod = "prod"
    public static let dev = "dev"
    // swiftlint:disable identifier_name
    public static let qa = "qa"
    // swiftlint:enable identifier_name
    public static let errorHeaderKey = "X-Error"
    public static let remoteAPIEventType = "remote_api"
    public static let tealiumURLScheme = "tealium"
    static let killVisitorSession = "kill_visitor_session"
    static let leaveTraceQueryParam = "leave_trace"
    static let traceIdQueryParam = "tealium_trace_id"
    static let deepLink = "deep_link"
}

public enum TealiumTrackType: String {
    case view           // Whenever content is displayed to the user.
    case event

    var description: String {
        switch self {
        case .view:
            return "view"
        case .event:
            return "event"
        }
    }

}

public typealias TealiumCompletion = ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)

public protocol TealiumErrorEnum: LocalizedError {}

// Add default localizedDescription
public extension TealiumErrorEnum {
    var errorDescription: String? {
        return "\(type(of: self)).\(self)"
    }
}
