//
//  TealiumConfig.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

/// Configuration object for any Tealium instance.
open class TealiumConfig {

    public let account: String
    public let profile: String
    public let environment: String
    public let dataSource: String?
    public lazy var options = [String: Any]()

    /// The start and stop timed events to be tracked automatically.
    /// Optionally provide a name for the timed event. Default  timed event name will be `start_event_name::end_event_name`
    /// - Usage: `config.timedEventTriggers = [TimedEventTrigger(start: "product_view", stop: "order_complete")]`
    /// - Optional usage: `config.timedEventTriggers = [TimedEventTrigger(start: "product_view", stop: "order_complete", name: "time_to_purchase")]`
    public var timedEventTriggers: [TimedEventTrigger]? {
        get {
            options[TealiumConfigKey.timedEventTriggers] as? [TimedEventTrigger]
        }

        set {
            options[TealiumConfigKey.timedEventTriggers] = newValue
        }
    }

    /// Intended for internal use only. Provides access to the internal Tealium logger instance.
    public var logger: TealiumLoggerProtocol? {
        get {
            options[TealiumConfigKey.logger] as? TealiumLoggerProtocol
        }

        set {
            options[TealiumConfigKey.logger] = newValue
        }
    }

    /// Set to `false` to disable the Tealium AppDelegate proxy for deep link handling.
    /// Default `true`.
    ///
    /// WARNING:
    /// No longer used. To disable this behavior use the info.plist flag `TealiumAutotrackingDeepLinkEnabled` with the boolean value of `false`
    @available(*, deprecated, message: "Add an info.plist flag `TealiumAutotrackingDeepLinkEnabled` with the boolean value of `false` to disable this behavior")
    public var appDelegateProxyEnabled: Bool {
        get {
            options[TealiumConfigKey.appDelegateProxy] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.appDelegateProxy] = newValue
        }
    }

    /// Define the conversion event and value if using `SKAdNetwork.updateConversionValue(_ value:)`
    /// The key in the dictionary is the `tealium_event` for which to count as a conversion and the value in the dictionary is the variable that holds the conversion value.
    /// Conversion value must be an `Int` and between `0-63`
    /// - Usage: `config.skAdConversionKeys = ["purchase": "order_subtotal"]`
    public var skAdConversionKeys: [String: String]? {
        get {
            options[TealiumConfigKey.skAdConversionKeys] as? [String: String]
        }

        set {
            options[TealiumConfigKey.skAdConversionKeys] = newValue
        }
    }

    /// Set to `false` to disable data migration from the Objective-c library
    /// Default `true`.
    public var shouldMigratePersistentData: Bool {
        get {
            options[TealiumConfigKey.shouldMigrate] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.shouldMigrate] = newValue
        }
    }

    /// Provides the option to add custom `DispatchValidator`s to control whether events should be dispatched, queued, or dropped
    public var dispatchValidators: [DispatchValidator]? {
        get {
            options[TealiumConfigKey.dispatchValidators] as? [DispatchValidator]
        }

        set {
            options[TealiumConfigKey.dispatchValidators] = newValue
        }
    }

    /// Provides the option to add custom `DispatchListener`s to listen for tracking calls just prior to dispatch
    public var dispatchListeners: [DispatchListener]? {
        get {
            options[TealiumConfigKey.dispatchListeners] as? [DispatchListener]
        }

        set {
            options[TealiumConfigKey.dispatchListeners] = newValue
        }
    }

    /// Allows configuration of optional Tealium Collectors
    public var collectors: [Collector.Type]? {
        get {
            options[TealiumConfigKey.collectors] as? [Collector.Type]
        }

        set {
            options[TealiumConfigKey.collectors] = newValue
        }
    }

    /// Allows configuration of optional Tealium Dispatchers
    public var dispatchers: [Dispatcher.Type]? {
        get {
            options[TealiumConfigKey.dispatchers] as? [Dispatcher.Type]
        }

        set {
            options[TealiumConfigKey.dispatchers] = newValue
        }
    }

    /// Returns a deep copy of the config object
    public var copy: TealiumConfig {
        return TealiumConfig(account: self.account,
                             profile: self.profile,
                             environment: self.environment,
                             dataSource: self.dataSource,
                             options: options)
    }

    /// Prevents session counting if false
    public var sessionCountingEnabled: Bool {
        get {
            options[TealiumConfigKey.sessionCountingEnabled] as? Bool ?? true
        }
        set {
            options[TealiumConfigKey.sessionCountingEnabled] = newValue
        }
    }

    /// Convenience constructor.
    ///
    /// - Parameters:
    ///     - account: Tealium Account.
    ///     - profile: Tealium Profile.
    ///     - environment: Tealium Environment. 'prod' recommended for release.
    public convenience init(account: String,
                            profile: String,
                            environment: String) {
        self.init(account: account,
                  profile: profile,
                  environment: environment,
                  dataSource: nil,
                  options: nil)
    }

    /// Convenience constructor.
    ///
    /// - Parameters:
    ///     - account: `String` Tealium Account.
    ///     - profile: `String` Tealium Profile.
    ///     - environment: `String` Tealium Environment. 'prod' recommended for release.
    ///     - dataSource: `String?` Optional dataSource obtained from UDH.
    public convenience init(account: String,
                            profile: String,
                            environment: String,
                            dataSource: String?) {
        self.init(account: account,
                  profile: profile,
                  environment: environment,
                  dataSource: dataSource,
                  options: nil)
    }

    /// Primary constructor.
    ///
    /// - Parameters:
    ///     - account: Tealium account name string to use.
    ///     - profile: Tealium profile string.
    ///     - environment: Tealium environment string.
    ///     - options: Optional [String:Any] dictionary meant primarily for module use.
    public init(account: String,
                profile: String,
                environment: String,
                dataSource: String? = nil,
                options: [String: Any]?) {
        self.account = account
        self.environment = environment
        self.profile = profile
        self.dataSource = dataSource
        if let options = options {
            self.options = options
        }
        self.logger = self.logger ?? getNewLogger()
    }

    func getNewLogger() -> TealiumLoggerProtocol {
        switch loggerType {
        case .custom(let logger):
            return logger
        default:
            return TealiumLogger(config: self)
        }
    }

}

extension TealiumConfig: Equatable, Hashable {

    public static func == (lhs: TealiumConfig, rhs: TealiumConfig ) -> Bool {
        if lhs.account != rhs.account { return false }
        if lhs.profile != rhs.profile { return false }
        if lhs.environment != rhs.environment { return false }
        let lhsKeys = lhs.options.keys.sorted()
        let rhsKeys = rhs.options.keys.sorted()
        if lhsKeys.count != rhsKeys.count { return false }
        for (index, key) in lhsKeys.enumerated() {
            if key != rhsKeys[index] { return false }
            let lhsValue = String(describing: lhs.options[key])
            let rhsValue = String(describing: rhs.options[key])
            if lhsValue != rhsValue { return false }
        }

        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(profile)
        hasher.combine(environment)
    }

}

public extension TealiumConfig {

    /// Sets a known visitor ID. Must be unique (i.e. UUID).
    /// Should only be used in cases where the user has an existing visitor ID
    var existingVisitorId: String? {
        get {
            options[TealiumConfigKey.visitorId] as? String
        }

        set {
            options[TealiumConfigKey.visitorId] = newValue
        }
    }

}

// MARK: Publish Settings
public extension TealiumConfig {

    /// Whether or not remote publish settings should be used. Default `true`.
    var shouldUseRemotePublishSettings: Bool {
        get {
            options[TealiumConfigKey.publishSettings] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.publishSettings] = newValue
        }
    }

    /// Overrides the publish settings URL. Default is https://tags.tiqcdn.com/utag/ACCOUNT/PROFILE/ENVIRONMENT/mobile.html
    /// If overriding, you must provide the entire URL, not just the domain.
    /// Usage: `config.publishSettingsURL = "https://mycompany.org/utag/ACCOUNT/PROFILE/ENVIRONMENT/mobile.html"`
    /// Takes precendence over `publishSettingsProfile`
    var publishSettingsURL: String? {
        get {
            options[TealiumConfigKey.publishSettingsURL] as? String
        }

        set {
            options[TealiumConfigKey.publishSettingsURL] = newValue
        }
    }

    /// Overrides the publish settings profile. Default is to use the profile set on the `TealiumConfig` object.
    /// Use this if you need to load the publish settings from a central profile that is different to the profile you're sending data to.
    /// Usage: `config.publishSettingsProfile = "myprofile"`
    var publishSettingsProfile: String? {
        get {
            options[TealiumConfigKey.publishSettingsProfile] as? String
        }

        set {
            options[TealiumConfigKey.publishSettingsProfile] = newValue
        }
    }

    /// If `false`, the entire library is disabled, and no tracking calls are sent.
    var isEnabled: Bool? {
        get {
            options[TealiumConfigKey.libraryEnabled] as? Bool
        }

        set {
            options[TealiumConfigKey.libraryEnabled] = newValue
        }
    }

    /// If `false`, the the tag management module is disabled and will not be used for dispatching events
    var isTagManagementEnabled: Bool {
        get {
            options[TealiumConfigKey.tagManagementModuleName] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.tagManagementModuleName] = newValue
        }
    }

    /// If `false`, the the collect module is disabled and will not be used for dispatching events
    var isCollectEnabled: Bool {
        get {
            options[TealiumConfigKey.collectModuleName] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.collectModuleName] = newValue
        }
    }

    /// If `true`, calls will only be sent if the device has sufficient battery levels (>20%).
    var batterySaverEnabled: Bool? {
        get {
            options[TealiumConfigKey.batterySaver] as? Bool
        }

        set {
            options[TealiumConfigKey.batterySaver] = newValue
        }
    }

    /// How long the data persists in the app if no data has been sent back (`-1` = no dispatch expiration). Default value is `7` days.
    var dispatchExpiration: Int? {
        get {
            options[TealiumConfigKey.batchExpirationDaysKey] as? Int
        }

        set {
            options[TealiumConfigKey.batchExpirationDaysKey] = newValue
        }
    }

    /// Enables (`true`) or disables (`false`) event batching. Default `false`
    var batchingEnabled: Bool? {
        get {
            // batching requires disk storage
            guard diskStorageEnabled == true else {
                return false
            }
            return options[TealiumConfigKey.batchingEnabled] as? Bool
        }

        set {
            options[TealiumConfigKey.batchingEnabled] = newValue
        }
    }

    /// How many events should be batched together
    /// If set to `1`, events will be sent individually
    var batchSize: Int {
        get {
            options[TealiumConfigKey.batchSizeKey] as? Int ?? TealiumValue.maxEventBatchSize
        }

        set {
            let size = newValue > TealiumValue.maxEventBatchSize ? TealiumValue.maxEventBatchSize: newValue
            options[TealiumConfigKey.batchSizeKey] = size
        }

    }

    /// The maximum amount of events that will be stored offline
    /// Oldest events are deleted to make way for new events if this limit is reached
    var dispatchQueueLimit: Int? {
        get {
            options[TealiumConfigKey.queueSizeKey] as? Int
        }

        set {
            options[TealiumConfigKey.queueSizeKey] = newValue
        }
    }

    /// Restricts event data transmission to wifi only
    /// Data will be queued if on cellular connection
    var wifiOnlySending: Bool? {
        get {
            options[TealiumConfigKey.wifiOnlyKey] as? Bool
        }

        set {
            options[TealiumConfigKey.wifiOnlyKey] = newValue
        }
    }

    /// Determines how often the publish settings should be fetched from the CDN
    /// Usually set automatically by the response from the remote publish settings
    var minutesBetweenRefresh: Double? {
        get {
            options[TealiumConfigKey.minutesBetweenRefresh] as? Double
        }

        set {
            options[TealiumConfigKey.minutesBetweenRefresh] = newValue
        }
    }

    /// Sets the expiry for the Consent Manager preferences.
    var consentExpiry: (time: Int, unit: TimeUnit)? {
        get {
            options[TealiumConfigKey.consentExpiry] as? (Int, TimeUnit)
        }

        set {
            options[TealiumConfigKey.consentExpiry] = newValue
        }
    }

    /// Defines the consent expiration callback
    var onConsentExpiration: (() -> Void)? {
        get {
            options[TealiumConfigKey.consentExpiryCallback] as? (() -> Void)
        }

        set {
            options[TealiumConfigKey.consentExpiryCallback] = newValue
        }
    }

    /// Allows the Consent Categories key to be overridden
    var overrideConsentCategoriesKey: String? {
        get {
            options[TealiumConfigKey.overrideConsentCategoriesKey] as? String
        }

        set {
            options[TealiumConfigKey.overrideConsentCategoriesKey] = newValue
        }
    }
}

// MARK: Deep Linking/QR Trace
public extension TealiumConfig {

    var deepLinkTrackingEnabled: Bool {
        get {
            options[TealiumConfigKey.deepLinkTrackingEnabled] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.deepLinkTrackingEnabled] = newValue
        }
    }

    var qrTraceEnabled: Bool {
        get {
            options[TealiumConfigKey.qrTraceEnabled] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.qrTraceEnabled] = newValue
        }
    }
}
