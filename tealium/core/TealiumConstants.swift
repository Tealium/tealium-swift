//
//  TealiumConstants.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import UIKit
// MARK: VALUES
#endif

public enum Collectors {}

public enum Dispatchers {}

public enum TealiumValue {
    public static let libraryName = "swift"
    public static let libraryVersion = "2.1.1"
    // This is the current limit for performance reasons. May be increased in future
    public static let maxEventBatchSize = 10
    public static let defaultMinimumDiskSpace: Int32 = 20_000_000
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
    public static let location = "Location"
    public static let remotecommands = "RemoteCommands"
    public static let tagmanagement = "TagManagement"
    public static let visitorservice = "VisitorService"
}

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
    public static let updateConsentCookieEventNames = ["update_consent_cookie", "set_dns_state"]
    public static let jsNotificationName = "com.tealium.tagmanagement.jscommand"
    public static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
    public static let jsCommand = "js"
    // used for remote commands
    public static let tealiumURLScheme = "tealium"
    public static let dataSource = "tealium_datasource"
    public static let sessionId = "tealium_session_id"
    public static let visitorId = "tealium_visitor_id"
    public static let random = "tealium_random"
    public static let uuid = "app_uuid"
    public static let requestUUID = "request_uuid"
    public static let simpleModel = "model_name" // e.g. iPhone 5s // OLD: device
    public static let device = "device" // == model_name
    public static let deviceType = "device_type"
    public static let fullModel = "model_variant" // e.g. CDMA, GSM
    public static let architecture = "device_architecture"
    public static let cpuType = "device_cputype"
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
    public static let publishSettings = "remote_publish_settings"
    public static let publishSettingsURL = "publish_settings_url"
    public static let publishSettingsProfile = "publish_settings_profile"
    public static let enabledModules = "enabled_modules"
    public static let libraryEnabled = "library_is_enabled"
    public static let batterySaver = "battery_saver"
    public static let queueSizeKey = "queue_size"
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
    static let qrTraceEnabled = "qr_trace_enabled"
    static let deepLinkURL = "deep_link_url"
    static let deepLinkQueryPrefix = "deep_link_param"
    static let killVisitorSession = "kill_visitor_session"
    static let killVisitorSessionEvent = "event"
    static let leaveTraceQueryParam = "leave_trace"
    static let traceIdQueryParam = "tealium_trace_id"
    public static let traceId = "cp.trace_id"
    static let appDelegateProxy = "app_delegate_proxy"
    static let skAdConversionKeys = "attribution_conversion_keys"
    static let hostedDataLayerKeys = "hosted_data_layer_keys"
    static let hostedDataLayerExpiry = "hosted_data_layer_expiry"
    static let origin = "origin"
    static let shouldMigrate = "should_migrate_data"
}

public enum TealiumTrackType {
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

// swiftlint:disable identifier_name
public enum HttpStatusCodes: Int {
    case notModified = 304
    case ok = 200
}
// swiftlint:enable identifier_name
