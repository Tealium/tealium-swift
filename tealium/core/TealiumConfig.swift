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

    // returns a new instance of the class to avoid accidental references
    var copy: TealiumConfig {
            return TealiumConfig(account: self.account, profile: self.profile, environment: self.environment, datasource: self.datasource, optionalData: self.optionalData)
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
        if lhs.getModulesList() != rhs.getModulesList() { return false }
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
    func getModulesList() -> TealiumModulesList? {
        guard let list = self.optionalData[TealiumModulesListKey.config] as? TealiumModulesList else {
            return nil
        }

        return list
    }

    /// Set a net modules list to this config object.
    ///￼
    /// - Parameter list: The TealiumModulesList to assign.
    func setModulesList(_ list: TealiumModulesList ) {
        self.optionalData[TealiumModulesListKey.config] = list
    }
}

// MARK: Logger
public extension TealiumConfig {

    /// - Returns: `TealiumLogLevel` (default is `.errors`)
    func getLogLevel() -> TealiumLogLevel {
        if let level = self.optionalData[TealiumKey.logLevelConfig] as? TealiumLogLevel {
            return level
        }

        // Default
        return defaultTealiumLogLevel
    }

    /// Sets the log level to be used by the library
    ///
    /// - Parameter logLevel: `TealiumLogLevel`
    func setLogLevel(_ logLevel: TealiumLogLevel) {
        self.optionalData[TealiumKey.logLevelConfig] = logLevel
    }
}

public extension TealiumConfig {
    /// Sets a known visitor ID. Must be unique (i.e. UUID).
    /// Should only be used in cases where the user has an existing visitor ID
    func setExistingVisitorId(_ visitorId: String) {
        self.optionalData[TealiumKey.visitorId] = visitorId
    }

    func getExistingVisitorId() -> String? {
        return self.optionalData[TealiumKey.visitorId] as? String
    }
}
