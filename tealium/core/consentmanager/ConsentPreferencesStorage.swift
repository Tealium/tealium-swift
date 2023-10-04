//
//  ConsentPreferencesStorage.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumBackupStorage {
    var consentPreferences: UserConsentPreferences? {
        get {
            guard let data = userDefaults?.object(forKey: TealiumBacupKey.consentPreferences) as? Data else { return nil }
            return try? JSONDecoder().decode(UserConsentPreferences.self, from: data)
        }
        set {
            guard var newValue = newValue else {
                userDefaults?.removeObject(forKey: TealiumBacupKey.consentPreferences)
                return
            }
            do {
                userDefaults?.set(try JSONEncoder().encode(newValue),
                                  forKey: TealiumBacupKey.consentPreferences)
            } catch {
                print(error)
            }
        }
    }
}

extension TealiumBacupKey {
    static let consentPreferences = "consent_preferences"
}

/// Dedicated persistent storage for consent preferences
class ConsentPreferencesStorage {

    let diskStorage: TealiumDiskStorageProtocol
    let backupStorage: TealiumBackupStorage
    var preferences: UserConsentPreferences? {
        get {
            guard let data = diskStorage.retrieve(as: UserConsentPreferences.self) else {
                return backupStorage.consentPreferences
            }
            return data
        }

        set {
            backupStorage.consentPreferences = newValue
            guard let newValue = newValue else {
                diskStorage.delete(completion: nil)
                return
            }
            diskStorage.save(newValue, completion: nil)
        }
    }

    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance to use for storing consent preferences
    public init(diskStorage: TealiumDiskStorageProtocol, backupStorage: TealiumBackupStorage) {
        self.diskStorage = diskStorage
        self.backupStorage = backupStorage
    }
}
