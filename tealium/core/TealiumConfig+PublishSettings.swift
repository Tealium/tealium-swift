//
//  TealiumConfig+PublishSettings.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

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
            let size = newValue > TealiumValue.maxEventBatchSize ? TealiumValue.maxEventBatchSize : newValue
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
