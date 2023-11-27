//
//  Migrator.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public enum MigrationKey {
    static let lifecycle = "lifecycle"
    static let migratedLifecycle = "migrated_lifecycle"
    static let consentConfiguration = "teal_consent_configuration_archivable"
    static let consentStatus = "userConsentStatus"
    static let consentLogging = "enableConsentLogging"
    static let consentCategories = "userConsentCategories"
    static let TEALConsentConfiguration = "TEALConsentConfiguration"
}

public protocol Migratable {
    func migratePersistent(dataLayer: DataLayerManagerProtocol)
}

struct LegacyConsentUnarchiver: ConsentUnarchiver {

    func decodeObject(fromData data: Data) throws -> Any? {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.setClass(LegacyConsentConfiguration.self, forClassName: MigrationKey.TEALConsentConfiguration)
        unarchiver.requiresSecureCoding = true
        let unarchived = unarchiver.decodeObject(of: [LegacyConsentConfiguration.self], forKey: NSKeyedArchiveRootObjectKey)
        unarchiver.finishDecoding()
        return unarchived
    }
}

public struct Migrator: Migratable {
    /// These are keys that were written to the DataLayer in the past but are now moved to a collector or are entirely removed
    var excludedKeysFromMigration: [String] {
        [
            TealiumDataKey.appVersion,
            "uuid",
            "visitor_id",
            "last_track_event",
            "last_session_created"
        ]
    }
    var config: TealiumConfig
    var userDefaults: Storable? = UserDefaults.standard
    var unarchiver: ConsentUnarchiver? = LegacyConsentUnarchiver()
    var instance: String {
        "\(config.account).\(config.profile).\(config.environment)"
    }

    func extractConsentPreferences() -> [String: Any] {
        guard let consentConfiguration = retrieve(for: MigrationKey.consentConfiguration) as? Data else {
            return [String: Any]()
        }
        guard let unarchivedConsentConfiguration = try? unarchive(data: consentConfiguration) as? ConsentConfigurable else {
            return [String: Any]()
        }
        return [TealiumDataKey.consentStatus: unarchivedConsentConfiguration.consentStatus,
                TealiumDataKey.consentCategoriesKey: unarchivedConsentConfiguration.consentCategories,
                TealiumDataKey.consentLoggingEnabled: unarchivedConsentConfiguration.enableConsentLogging]
    }

    func extractLifecycleData(from dictionary: [String: Any]) -> [String: Any] {
        var migrated = [String: Any]()
        let migratedLifecycle = dictionary
            .filter { $0.key.contains(MigrationKey.lifecycle) }
        migratedLifecycle.forEach {
            if let stringVal = $0.value as? String,
               let intVal = Int(stringVal) {
                migrated[$0.key] = intVal
            } else {
                migrated[$0.key] = $0.value
            }
        }
        var result = dictionary.filter { !$0.key.contains(MigrationKey.lifecycle) }
        if !migrated.isEmpty {
            result[MigrationKey.migratedLifecycle] = migrated
        }
        return result
    }

    func extractUserDefaults() -> [String: Any] {
        guard let legacyUserDefaults = retrieve(for: instance) as? [String: Any] else {
            return [String: Any]()
        }
        return extractLifecycleData(from: legacyUserDefaults)
    }

    public func migratePersistent(dataLayer: DataLayerManagerProtocol) {
        var info = extractUserDefaults()
        info += extractConsentPreferences()
        dataLayer.add(data: removeExcludedKeys(excludedKeysFromMigration, from: info),
                      expiry: .forever)
        dataLayer.delete(for: excludedKeysFromMigration) // For clients that migrated already in the past
        remove(for: instance)
        remove(for: MigrationKey.consentConfiguration)
    }

    func removeExcludedKeys(_ excludedKeys: [String], from data: [String: Any]) -> [String: Any] {
        data.filter { !excludedKeys.contains($0.key) }
    }

    func remove(for key: String) {
        userDefaults?.removeObject(forKey: key)
    }

    func retrieve(for key: String) -> Any? {
        userDefaults?.object(forKey: key)
    }

    func unarchive(data: Data) throws -> Any? {
        guard let unarchiver = unarchiver else {
                return nil
        }
        return try? unarchiver.decodeObject(fromData: data)
    }
}
