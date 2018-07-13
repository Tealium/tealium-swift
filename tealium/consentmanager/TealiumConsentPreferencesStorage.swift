//
//  TealiumConsentPreferencesStorage.swift
//  tealium-swift
//
//  Created by Craig Rouse on 26/04/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumConsentPreferencesStorage {

    static let consentStorage = UserDefaults.standard
    static let key = "consentpreferences"
    let readWriteQueue = ReadWrite("\(TealiumConsentPreferencesStorage.key).label")

    public init() {

    }

    func storeConsentPreferences(_ prefs: [String: Any]) {
        persist(prefs)
    }

    func retrieveConsentPreferences() -> [String: Any]? {
        return read()
    }

    func clearStoredPreferences() {
        readWriteQueue.write {
            TealiumConsentPreferencesStorage.consentStorage.removeObject(forKey: TealiumConsentPreferencesStorage.key)
        }
    }

    private func persist(_ dict: [String: Any]) {
        readWriteQueue.write {
            TealiumConsentPreferencesStorage.consentStorage.set(dict, forKey: TealiumConsentPreferencesStorage.key)
        }
    }

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
