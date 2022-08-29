//
//  AppDataModuleExtensions.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

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
