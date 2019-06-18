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
    let readWriteQueue = ReadWrite("\(TealiumConsentPreferencesStorage.key).label")

    public init() {

    }

    /// Saves the consent preferences to persistent storage
    ///
    /// - Parameter prefs: [String: Any] containing the current consent preferences
    func storeConsentPreferences(_ prefs: [String: Any]) {
        persist(prefs)
    }

    /// Gets the saved consent preferences from persistent storage
    ///
    /// - Returns: [String: Any]? containing the saved consent preferences. Nil if empty.
    func retrieveConsentPreferences() -> [String: Any]? {
        return read()
    }

    /// Deletes all previously saved consent preferences from persistent storage
    func clearStoredPreferences() {
        readWriteQueue.write {
            TealiumConsentPreferencesStorage.consentStorage.removeObject(forKey: TealiumConsentPreferencesStorage.key)
        }
    }

    /// Saves the consent preferences to persistent storage
    ///
    /// - Parameter dict: [String: Any] containing the current consent preferences
    private func persist(_ dict: [String: Any]) {
        readWriteQueue.write {
            TealiumConsentPreferencesStorage.consentStorage.set(dict, forKey: TealiumConsentPreferencesStorage.key)
        }
    }

    /// Gets the saved consent preferences from persistent storage
    ///
    /// - Returns: [String: Any]? containing the saved consent preferences. Nil if empty.
    private func read() -> [String: Any]? {
        var preferences = [String: Any]()
        readWriteQueue.read {
            if let prefs = TealiumConsentPreferencesStorage.consentStorage.dictionary(forKey: TealiumConsentPreferencesStorage.key) {
                preferences = prefs
            }
        }
        return preferences.count > 0 ? preferences : nil
    }
}
