//
//  ConsentPreferencesStorage.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

/// Dedicated persistent storage for consent preferences
class ConsentPreferencesStorage {

    static let consentStorage = UserDefaults.standard
    static let key = "consentpreferences"
    let readWriteQueue = ReadWrite("\(ConsentPreferencesStorage.key).label")
    let diskStorage: TealiumDiskStorageProtocol
    var preferences: UserConsentPreferences? {
        get {
            readWriteQueue.read {
                guard let data = diskStorage.retrieve(as: UserConsentPreferences.self) else {
                    return nil
                }
                return data
            }
        }

        set {
            guard let newValue = newValue else {
                diskStorage.delete(completion: nil)
                return
            }
            diskStorage.save(newValue, completion: nil)
        }
    }

    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance to use for storing consent preferences
    public init(diskStorage: TealiumDiskStorageProtocol) {
        self.diskStorage = diskStorage
    }
}
