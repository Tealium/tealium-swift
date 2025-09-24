//
//  DeviceDataExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumConfigKey {
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"

    static let isBatteryReportingEnabled = "com.tealium.devicedata.battery.enable"

    static let isScreenReportingEnabled = "com.tealium.devicedata.screen.enable"
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

    /// If enabled it will start recording of battery percentage and will add it to the data layer for iOS. Default is `true`.
    var batteryReportingEnabled: Bool {
        get {
            return options[TealiumConfigKey.isBatteryReportingEnabled] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.isBatteryReportingEnabled] = newValue
        }
    }

    /// If enabled add screen orientation and resolution to the data layer. Default is `true`.
    var screenReportingEnabled: Bool {
        get {
            return options[TealiumConfigKey.isScreenReportingEnabled] as? Bool ?? true
        }

        set {
            options[TealiumConfigKey.isScreenReportingEnabled] = newValue
        }
    }

}

public extension Collectors {
    static let Device = DeviceDataModule.self
}
