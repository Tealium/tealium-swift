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
            guard let lhsValue = lhs.options[key], let rhsValue = rhs.options[key] else {
                if lhs.options[key] == nil && rhs.options[key] == nil {
                    continue
                } else {
                    return false
                }
            }
            if !areEqualValues(lhsValue, rhsValue) {
                return false
            }
        }
        return true
    }

    private static func areEqualValues(_ lhsValue: Any, _ rhsValue: Any) -> Bool {
        // This is safer than String comparing in case of reference types
        // But also WKWebViewConfiguration can only be described as String from main thread or it can crash
        if type(of: lhsValue) is AnyClass || type(of: rhsValue) is AnyClass { // If one of the values is a reference type, check the reference instead of the description
            return type(of: lhsValue) is AnyClass &&
               type(of: rhsValue) is AnyClass &&
               lhsValue as AnyObject === rhsValue as AnyObject
        }
        let lhsString = String(describing: lhsValue)
        let rhsString = String(describing: rhsValue)
        return lhsString == rhsString
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(account)
        hasher.combine(profile)
        hasher.combine(environment)
    }

}

// MARK: Known Visitor ID
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

    var sendDeepLinkEvent: Bool {
        get {
            options[TealiumConfigKey.sendDeepLinkEvent] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.sendDeepLinkEvent] = newValue
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
