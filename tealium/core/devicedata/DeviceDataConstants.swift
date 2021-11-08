//
//  DeviceDataConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum DeviceDataKey {
    public static let fileName = "device-names"
}

public extension TealiumDataKey {

    static let batteryPercent = "device_battery_percent"
    static let isCharging = "device_ischarging"
    static let appMemoryUsage = "app_memory_usage"
    static let memoryFree = "memory_free"
    static let memoryActive = "memory_active"
    static let memoryInactive = "memory_inactive"
    static let memoryCompressed = "memory_compressed"
    static let memoryWired = "memory_wired"
    static let physicalMemory = "memory_physical"
    static let orientation = "device_orientation"
    static let fullOrientation = "device_orientation_extended"
    static let osBuild = "device_os_build"
    static let osVersion = "device_os_version"
    static let carrier = "carrier"
    static let carrierMNC = "carrier_mnc"
    static let carrierMCC = "carrier_mcc"
    static let carrierISO = "carrier_iso"
    static let appOrientation = "app_orientation"
    static let deviceOrientation = "device_orientation"
    static let appOrientationExtended = "app_orientation_extended"
    static let manufacturer = "device_manufacturer"
}

enum DeviceDataModuleKey {
    static let moduleName = "devicedata"
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"
}

public enum DeviceDataValue {
    static let appleWatch = "Apple Watch"
    public static let manufacturer = "Apple"
}
