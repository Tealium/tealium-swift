//
//  DeviceDataConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum DeviceDataKey {

    public static let batteryPercent = "device_battery_percent"
    public static let isCharging = "device_ischarging"
    public static let appMemoryUsage = "app_memory_usage"
    public static let memoryFree = "memory_free"
    public static let memoryActive = "memory_active"
    public static let memoryInactive = "memory_inactive"
    public static let memoryCompressed = "memory_compressed"
    public static let memoryWired = "memory_wired"
    public static let physicalMemory = "memory_physical"
    public static let orientation = "device_orientation"
    public static let fullOrientation = "device_orientation_extended"
    public static let osBuild = "device_os_build"
    public static let osVersion = "device_os_version"
    public static let carrier = "carrier"
    public static let carrierMNC = "carrier_mnc"
    public static let carrierMCC = "carrier_mcc"
    public static let carrierISO = "carrier_iso"
    public static let fileName = "device-names"
    public static let appOrientation = "app_orientation"
    public static let deviceOrientation = "device_orientation"
    public static let appOrientationExtended = "app_orientation_extended"
}

enum DeviceDataModuleKey {
    static let moduleName = "devicedata"
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"
}

public enum DeviceDataValue {
    static let appleWatch = "Apple Watch"
}
