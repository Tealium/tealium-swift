//
//  TealiumConfig.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

/// Configuration object for any Tealium instance.
open class TealiumConfig {

    public let account: String
    public let profile: String
    public let environment: String
    public let datasource: String?
    public lazy var optionalData = [String: Any]()

    public var copy: TealiumConfig {
            return TealiumConfig(account: self.account,
                                 profile: self.profile,
                                 environment: self.environment,
                                 datasource: self.datasource,
                                 optionalData: optionalData)
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
                  datasource: nil,
                  optionalData: nil)
    }

    /// Convenience constructor.
    ///
    /// - Parameters:
    ///     - account: `String` Tealium Account.
    ///     - profile: `String` Tealium Profile.
    ///     - environment: `String` Tealium Environment. 'prod' recommended for release.
    ///     - dataSource: `String?` Optional datasource obtained from UDH.
    public convenience init(account: String,
                            profile: String,
                            environment: String,
                            datasource: String?) {
        self.init(account: account,
                  profile: profile,
                  environment: environment,
                  datasource: datasource,
                  optionalData: nil)
    }

    /// Primary constructor.
    ///
    /// - Parameters:
    ///     - account: Tealium account name string to use.
    ///     - profile: Tealium profile string.
    ///     - environment: Tealium environment string.
    ///     - optionalData: Optional [String:Any] dictionary meant primarily for module use.
    public init(account: String,
                profile: String,
                environment: String,
                datasource: String? = nil,
                optionalData: [String: Any]?) {
        self.account = account
        self.environment = environment
        self.profile = profile
        self.datasource = datasource
        if let optionalData = optionalData {
            self.optionalData = optionalData
        }
    }

}

extension TealiumConfig: Equatable {

    public static func == (lhs: TealiumConfig, rhs: TealiumConfig ) -> Bool {
        if lhs.account != rhs.account { return false }
        if lhs.profile != rhs.profile { return false }
        if lhs.environment != rhs.environment { return false }
        let lhsKeys = lhs.optionalData.keys.sorted()
        let rhsKeys = rhs.optionalData.keys.sorted()
        if lhs.modulesList != rhs.modulesList { return false }
        if lhsKeys.count != rhsKeys.count { return false }
        for (index, key) in lhsKeys.enumerated() {
            if key != rhsKeys[index] { return false }
            let lhsValue = String(describing: lhs.optionalData[key])
            let rhsValue = String(describing: rhs.optionalData[key])
            if lhsValue != rhsValue { return false }
        }

        return true
    }

}

public extension TealiumConfig {

    /// Get the existing modules list assigned to this config object.
    ///
    /// - Returns: TealiumModulesList as an optional.
    @available(*, deprecated, message: "Please switch to config.modulesList")
    func getModulesList() -> TealiumModulesList? {
        modulesList
    }

    /// Set a net modules list to this config object.
    ///￼
    /// - Parameter list: The TealiumModulesList to assign.
    @available(*, deprecated, message: "Please switch to config.modulesList")
    func setModulesList(_ list: TealiumModulesList ) {
        modulesList = list
    }

    var modulesList: TealiumModulesList? {
        get {
            optionalData[TealiumModulesListKey.config] as? TealiumModulesList
        }

        set {
            optionalData[TealiumModulesListKey.config] = newValue
        }
    }
}

// MARK: Logger
public extension TealiumConfig {

    /// - Returns: `TealiumLogLevel` (default is `.errors`)
    @available(*, deprecated, message: "Please switch to config.logLevel")
    func getLogLevel() -> TealiumLogLevel? {
       logLevel
    }

    /// Sets the log level to be used by the library
    ///
    /// - Parameter logLevel: `TealiumLogLevel`
    @available(*, deprecated, message: "Please switch to config.logLevel")
    func setLogLevel(_ logLevel: TealiumLogLevel) {
        self.logLevel = logLevel
    }

    /// Sets a known visitor ID. Must be unique (i.e. UUID).
    /// Should only be used in cases where the user has an existing visitor ID
    var logLevel: TealiumLogLevel? {
        get {
            optionalData[TealiumKey.logLevelConfig] as? TealiumLogLevel
        }

        set {
            optionalData[TealiumKey.logLevelConfig] = newValue
        }
    }
}

public extension TealiumConfig {
    /// Sets a known visitor ID. Must be unique (i.e. UUID).
    /// Should only be used in cases where the user has an existing visitor ID
    @available(*, deprecated, message: "Please switch to config.existingVisitorId")
    func setExistingVisitorId(_ visitorId: String) {
        existingVisitorId = visitorId
    }

    @available(*, deprecated, message: "Please switch to config.existingVisitorId")
    func getExistingVisitorId() -> String? {
        existingVisitorId
    }

    /// Sets a known visitor ID. Must be unique (i.e. UUID).
    /// Should only be used in cases where the user has an existing visitor ID
    var existingVisitorId: String? {
        get {
            optionalData[TealiumKey.visitorId] as? String
        }

        set {
            optionalData[TealiumKey.visitorId] = newValue
        }
    }

}

// MARK: Publish Settings
public extension TealiumConfig {

    /// Whether or not remote publish settings should be used. Default `true`.
    var shouldUseRemotePublishSettings: Bool {
        get {
            optionalData[TealiumKey.publishSettings] as? Bool ?? true
        }

        set {
            optionalData[TealiumKey.publishSettings] = newValue
        }
    }

    /// Overrides the publish settings URL. Default is https://tags.tiqcdn.com/utag/ACCOUNT/PROFILE/ENVIRONMENT/mobile.html
    /// If overriding, you must provide the entire URL, not just the domain.
    /// Usage: `config.publishSettingsURL = "https://mycompany.org/utag/ACCOUNT/PROFILE/ENVIRONMENT/mobile.html"`
    /// Takes precendence over `publishSettingsProfile`
    var publishSettingsURL: String? {
        get {
            optionalData[TealiumKey.publishSettingsURL] as? String
        }

        set {
            optionalData[TealiumKey.publishSettingsURL] = newValue
        }
    }

    /// Overrides the publish settings profile. Default is to use the profile set on the `TealiumConfig` object.
    /// Use this if you need to load the publish settings from a central profile that is different to the profile you're sending data to.
    /// Usage: `config.publishSettingsProfile = "myprofile"`
    var publishSettingsProfile: String? {
        get {
            optionalData[TealiumKey.publishSettingsProfile] as? String
        }

        set {
            optionalData[TealiumKey.publishSettingsProfile] = newValue
        }
    }

    /// If `false`, the entire library is disabled, and no tracking calls are sent.
    var isEnabled: Bool? {
        get {
            optionalData[TealiumKey.libraryEnabled] as? Bool
        }

        set {
            optionalData[TealiumKey.libraryEnabled] = newValue
        }
    }

    /// If `true`, calls will only be sent if the device has sufficient battery levels (>20%).
    var batterySaverEnabled: Bool? {
        get {
            optionalData[TealiumKey.batterySaver] as? Bool
        }

        set {
            optionalData[TealiumKey.batterySaver] = newValue
        }
    }

    /// How long the data persists in the app if no data has been sent back (`-1` = no dispatch expiration). Default value is `7` days.
    var dispatchExpiration: Int? {
        get {
            optionalData[TealiumKey.batchExpirationDaysKey] as? Int
        }

        set {
            optionalData[TealiumKey.batchExpirationDaysKey] = newValue
        }
    }

    /// Enables (`true`) or disables (`false`) event batching. Default `false`
    var batchingEnabled: Bool? {
        get {
            // batching requires disk storage
            guard diskStorageEnabled == true else {
                return false
            }
            return optionalData[TealiumKey.batchingEnabled] as? Bool
        }

        set {
            optionalData[TealiumKey.batchingEnabled] = newValue
        }
    }

    /// How many events should be batched together
    /// If set to `1`, events will be sent individually
    var batchSize: Int {
        get {
            optionalData[TealiumKey.batchSizeKey] as? Int ?? TealiumValue.maxEventBatchSize
        }

        set {
            let size = newValue > TealiumValue.maxEventBatchSize ? TealiumValue.maxEventBatchSize: newValue
            optionalData[TealiumKey.batchSizeKey] = size
        }

    }

    /// The maximum amount of events that will be stored offline
    /// Oldest events are deleted to make way for new events if this limit is reached
    var dispatchQueueLimit: Int? {
        get {
            optionalData[TealiumKey.queueSizeKey] as? Int
        }

        set {
            optionalData[TealiumKey.queueSizeKey] = newValue
        }
    }

    /// Restricts event data transmission to wifi only
    /// Data will be queued if on cellular connection
    var wifiOnlySending: Bool? {
        get {
            optionalData[TealiumKey.wifiOnlyKey] as? Bool
        }

        set {
            optionalData[TealiumKey.wifiOnlyKey] = newValue
        }
    }

    /// Determines how often the publish settings should be fetched from the CDN
    /// Usually set automatically by the response from the remote publish settings
    var minutesBetweenRefresh: Double? {
        get {
            optionalData[TealiumKey.minutesBetweenRefresh] as? Double
        }

        set {
            optionalData[TealiumKey.minutesBetweenRefresh] = newValue
        }
    }
}
