//
//  AppDataModuleExtensions.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import CommonCrypto
import Foundation

public extension Collectors {
    static let AppData = AppDataModule.self
}

public extension TealiumConfigKey {
    static let visitorIdentityKey = "visitorIdentityKey"
}

public extension TealiumConfig {
    /// A key used to inspect the data layer for a stitching key to be used to store the current visitorId with.
    ///
    /// The current visitorId is stored with this key so if this key changes, we automatically reset it to a new value, and if it comes back to the old value we have a copy and don't have to generate a new one.
    /// Something like an email adress, or a unique identifier of the current user should be the field to which this key is pointing to.
    ///
    /// Note that the key is hashed and not saved in plain text when stored on disk.
    var visitorIdentityKey: String? {
        get {
            return options[TealiumConfigKey.visitorIdentityKey] as? String
        }
        set {
            options[TealiumConfigKey.visitorIdentityKey] = newValue
        }
    }
}

extension Data {
    func sha256() -> String {
        return hexStringFromData(input: digest(input: self as NSData))
    }

    private func digest(input: NSData) -> [UInt8] {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return hash
    }

    private  func hexStringFromData(input: [UInt8]) -> String {
        var hexString = ""
        for byte in input {
            hexString += String(format: "%02x", byte)
        }
        return hexString
    }
}

extension String {
    // Not to be used with unbounded strings like large files or similar
    func sha256() -> String? {
        if let stringData = self.data(using: String.Encoding.utf8) {
            return stringData.sha256()
        }
        return nil
    }
}

public extension Tealium {

    /// - Returns: `String` The Tealium Visitor Id
    var visitorId: String? {
        appDataModule?.data?[TealiumDataKey.visitorId] as? String
    }

    /// Resets the Tealium Visitor Id
    func resetVisitorId() {
        appDataModule?.resetVisitorId()
    }

    /// Clears the stored visitorIds and resets the current visitorId. Mainly for legal compliance reasons.
    ///
    /// This will also automatically reset the current visitorIds.
    /// Visitor Ids will still get stored in future, as long as the visitorIdentityKey is passed in the config and the dataLayer contains that key.
    ///
    /// - Warning: In order to avoid storing the newly reset visitorId with the current identity right after the storage is cleared, the identity key must be previously deleted from the data layer.
    func clearStoredVisitorIds() {
        appDataModule?.clearStoredVisitorIds()
    }

    internal var appDataModule: AppDataModule? {
        zz_internal_modulesManager?.collectors.first {
            $0 is AppDataModule
        } as? AppDataModule
    }

    /// Notifies of new visitorIds when we detect an identity change or when the visitorId is reset.
    var onVisitorId: TealiumObservable<String>? {
        return appDataModule?.onVisitorId
    }
}
