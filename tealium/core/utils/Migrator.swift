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

public struct Migrator: Migratable {

    var config: TealiumConfig
    var userDefaults: Storable? = UserDefaults.standard
    var unarchiver: Unarchivable?
    var instance: String {
        "\(config.account).\(config.profile).\(config.environment)"
    }

    func extractConsentPreferences() -> [String: Any] {
        guard let consentConfiguration = retrieve(for: MigrationKey.consentConfiguration) as? Data else {
            return [String: Any]()
        }
        set(type: LegacyConsentConfiguration.self, class: MigrationKey.TEALConsentConfiguration)
        guard let unarchivedConsentConfiguration = try? unarchive(data: consentConfiguration) as? ConsentConfigurable else {
            return [String: Any]()
        }
        remove(for: MigrationKey.consentConfiguration)
        return [ConsentKey.consentStatus: unarchivedConsentConfiguration.consentStatus,
                ConsentKey.consentCategoriesKey: unarchivedConsentConfiguration.consentCategories,
                ConsentKey.consentLoggingEnabled: unarchivedConsentConfiguration.enableConsentLogging]
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
        guard !result.isEmpty else {
            return [String: Any]()
        }
        result += [MigrationKey.migratedLifecycle: migrated]
        return result
    }

    func extractUserDefaults() -> [String: Any] {
        guard let legacyUserDefaults = retrieve(for: instance) as? [String: Any] else {
            return [String: Any]()
        }
        remove(for: instance)
        return extractLifecycleData(from: legacyUserDefaults)
    }

    public func migratePersistent(dataLayer: DataLayerManagerProtocol) {
        var info = extractUserDefaults()
        info += extractConsentPreferences()
        dataLayer.add(data: info, expiry: .forever)
    }

    func remove(for key: String) {
        userDefaults?.removeObject(forKey: key)
    }

    func retrieve(for key: String) -> Any? {
        userDefaults?.object(forKey: key)
    }

    func set(type: AnyClass, class name: String) {
        guard let unarchiver = unarchiver else {
            NSKeyedUnarchiver.setClass(type, forClassName: name)
            return
        }
        unarchiver.setClass(type, forClassName: name)
    }

    func unarchive(data: Data) throws -> Any? {
        guard let unarchiver = unarchiver else {
            return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
        }
        return try type(of: unarchiver).self.unarchiveTopLevelObjectWithData(data)
    }
}
