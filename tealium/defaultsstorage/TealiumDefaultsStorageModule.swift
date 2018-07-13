//
//  TealiumDefaultsStorageModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumDefaultsStorageKey {
    static let moduleName = "defaultsstorage"
    static let prefix = "com.tealium.defaultsstorage"
}

enum TealiumDefaultsStorageError: Error {
    case cannotWriteOrLoadFromDisk
    case noDataToSave
    case noSavedData
    case malformedSavedData
    case moduleNotYetReady
    case moduleDisabled
}

class TealiumDefaultsStorageModule: TealiumModule {

    // MARK: PUBLIC OVERRIDES

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDefaultsStorageKey.moduleName,
                priority: 360,
                build: 1,
                enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumLoadRequest {
            load(request)
        } else if let request = request as? TealiumSaveRequest {
            save(request)
        } else if let request = request as? TealiumDeleteRequest {
            delete(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    func prefixedKey(_ key: String) -> String {
        return "\(TealiumDefaultsStorageKey.prefix).\(key)"
    }

    func load(_ request: TealiumLoadRequest) {
        if self.isEnabled == false {
            didFailToFinish(request,
                    error: TealiumDefaultsStorageError.moduleDisabled)
            return
        }

        let key = prefixedKey(request.name)

        guard let rawData = UserDefaults.standard.object(forKey: key) else {
            // No saved data
            request.completion?(false,
                    nil,
                    TealiumDefaultsStorageError.noSavedData)
            didFinish(request)
            return
        }

        guard let data = rawData as? [String: Any] else {
            // Formatting check
            request.completion?(false,
                    nil,
                    TealiumDefaultsStorageError.malformedSavedData)
            didFinish(request)
            return
        }

        // Data retrieved, pass back to completion.
        request.completion?(true,
                data,
                nil)
        didFinish(request)
    }

    func save(_ request: TealiumSaveRequest) {
        if self.isEnabled == false {
            didFinish(request)
            return
        }

        let key = prefixedKey(request.name)
        let data = request.data

        UserDefaults.standard.set(data, forKey: key)

        request.completion?(true,
                data,
                nil)

        didFinish(request)
    }

    func delete(_ request: TealiumDeleteRequest) {
        if self.isEnabled == false {
            didFinish(request)
            return
        }
        let key = prefixedKey(request.name)

        UserDefaults.standard.removeObject(forKey: key)
        request.completion?(true,
                nil,
                nil)

        didFinish(request)
    }

    // MARK: PUBLIC GENERAL

    public class func dataExists(filepath: String) -> Bool {
        guard UserDefaults.standard.object(forKey: filepath) as? [String: Any] != nil else {
            return false
        }
        return true
    }

    /// Returns filename prefix to distinguish module persistence files by origin
    ///   accounts. Supports multi-lib instances and legacy 1.0.0-1.2.0 naming
    ///   scheme.
    ///
    /// - Parameter config: TealiumConfig object used to init lib instance.
    /// - Returns: Account unique id string.
    class func masterKey(config: TealiumConfig) -> String {
        let prefix = "\(config.account).\(config.profile).\(config.environment)"
        return prefix
    }
}
