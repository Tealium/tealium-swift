//
//  TealiumConsentPreferencesStorage.swift
//  tealium-swift
//
//  Created by Craig Rouse on 4/26/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if consentmanager
import TealiumCore
#endif

/// Dedicated persistent storage for consent preferences
class TealiumConsentPreferencesStorage {

    static let consentStorage = UserDefaults.standard
    static let key = "consentpreferences"
    let readWriteQueue = TealiumQueues.backgroundConcurrentQueue
    let diskStorage: TealiumDiskStorageProtocol

    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance to use for storing consent preferences
    public init(diskStorage: TealiumDiskStorageProtocol) {
        self.diskStorage = diskStorage
        if let preferences = retrieveConsentPreferencesFromUserDefaults() {
            self.persist(preferences)
        }
    }

    /// Saves the consent preferences to persistent storage￼.
    ///
    /// - Parameter preferences: `[String: Any]` containing the current consent preferences
    func storeConsentPreferences(_ preferences: TealiumConsentUserPreferences) {
        persist(preferences)
    }

    /// Gets the saved consent preferences from persistent storage.
    ///
    /// - Returns: `[String: Any]?` containing the saved consent preferences. `nil` if empty.
    func retrieveConsentPreferences() -> TealiumConsentUserPreferences? {
        return read()
    }

    /// One-time migration from userdefaults
    ///
    /// - Returns: `TealiumConsentUserPreferences?` containing the saved consent preferences. `nil` if empty.
    func retrieveConsentPreferencesFromUserDefaults() -> TealiumConsentUserPreferences? {
        var consentPreferences: TealiumConsentUserPreferences?
        if let data = UserDefaults.standard.dictionary(forKey: TealiumConsentPreferencesStorage.key) {
            var temp = TealiumConsentUserPreferences(consentStatus: nil, consentCategories: nil)
            temp.initWithDictionary(preferencesDictionary: data)
            consentPreferences = temp
            UserDefaults.standard.removeObject(forKey: TealiumConsentPreferencesStorage.key)
        }
        return consentPreferences
    }

    /// Deletes all previously saved consent preferences from persistent storage.
    func clearStoredPreferences() {
        diskStorage.delete(completion: nil)
    }

    /// Saves the consent preferences to persistent storage￼.
    ///
    /// - Parameter dictionary: `TealiumConsentUserPreferences` containing the current consent preferences
    private func persist(_ preferences: TealiumConsentUserPreferences) {
        diskStorage.save(preferences, completion: nil)
    }

    /// Gets the saved consent preferences from persistent storage.
    /// 
    /// - Returns: `TealiumConsentUserPreferences?` containing the saved consent preferences. Nil if empty.
    private func read() -> TealiumConsentUserPreferences? {
        readWriteQueue.read {
            guard let data = diskStorage.retrieve(as: TealiumConsentUserPreferences.self) else {
                    return nil
                }
            return data
        }
    }
}
