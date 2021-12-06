//
//  DeviceDataExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumConfigKey {
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"
}

public extension TealiumConfig {

    /// If enabled, this will add current memory reporting variables to the data layer
    /// Default is `false`
    var memoryReportingEnabled: Bool {
        get {
            return options[TealiumConfigKey.isMemoryReportingEnabled] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.isMemoryReportingEnabled] = newValue
        }
    }

}

public extension Collectors {
    static let Device = DeviceDataModule.self
}
