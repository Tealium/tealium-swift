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
