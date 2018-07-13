//
//  TealiumDeviceDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 8/3/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif
import Foundation
#if os(tvOS)
#elseif os (watchOS)
#else
import CoreTelephony
#endif
#if os(watchOS)
import WatchKit
#endif

import Darwin

enum TealiumDeviceDataModuleKey {
    static let moduleName = "devicedata"
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"
}

public enum TealiumDeviceDataValue {
    public static let unknown = "unknown"
    static let appleWatch = "Apple Watch"
}

class TealiumDeviceDataModule: TealiumModule {

    var data = [String: Any]()
    var isMemoryEnabled = false
    var deviceDataCollection: TealiumDeviceDataCollection

    required public init(delegate: TealiumModuleDelegate?) {
        self.deviceDataCollection = TealiumDeviceData()
        super.init(delegate: delegate)
    }

    init(delegate: TealiumModuleDelegate?, deviceDataCollection: TealiumDeviceDataCollection) {
        self.deviceDataCollection = deviceDataCollection
        super.init(delegate: delegate)
    }

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDeviceDataModuleKey.moduleName,
                                   priority: 525,
                                   build: 1,
                                   enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumTrackRequest {
            track(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        data = enableTimeData()
        let config = request.config
        isMemoryEnabled = config.isMemoryReportingEnabled()
        didFinish(request)
    }

    override func track(_ request: TealiumTrackRequest) {
        // Add device data to the data stream.
        var newData = request.data
        newData += data
        newData += trackTimeData()
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: request.completion)

        didFinish(newTrack)
    }

    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func enableTimeData() -> [String: Any] {
        var result = [String: Any]()

        result[TealiumDeviceDataKey.architecture] = deviceDataCollection.architecture()
        result[TealiumDeviceDataKey.osBuild] = TealiumDeviceData.oSBuild()
        result[TealiumDeviceDataKey.cpuType] = deviceDataCollection.cpuType()
        result.merge(deviceDataCollection.model()) { _, new -> Any in
            new
        }
        result[TealiumDeviceDataKey.osVersion] = TealiumDeviceData.oSVersion()
        result[TealiumDeviceDataKey.osName] = TealiumDeviceData.oSName()
        result[TealiumDeviceDataKey.resolution] = TealiumDeviceData.resolution()
        return result
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func trackTimeData() -> [String: Any] {
        var result = [String: Any]()

        result[TealiumDeviceDataKey.batteryPercent] = TealiumDeviceData.batteryPercent()
        result[TealiumDeviceDataKey.isCharging] = TealiumDeviceData.isCharging()
        result[TealiumDeviceDataKey.language] = TealiumDeviceData.iso639Language()
        if isMemoryEnabled == true {
            result.merge(deviceDataCollection.getMemoryUsage()) { _, new -> Any in
                new
            }
        }
        result.merge(deviceDataCollection.orientation()) { _, new -> Any in
            new
        }
        result.merge(TealiumDeviceData.carrierInfo()) { _, new -> Any in
            new
        }
        return result
    }
}

public enum TealiumDeviceDataKey {
    public static let simpleModel = "model_name" // e.g. iPhone 5s
    public static let fullModel = "model_variant" // e.g. CDMA, GSM
    public static let architecture = "cpu_architecture"
    public static let batteryPercent = "battery_percent"
    public static let cpuType = "cpu_type"
    public static let isCharging = "device_is_charging"
    public static let language = "user_locale"
    public static let appMemoryUsage = "app_memory_usage"
    public static let memoryFree = "memory_free"
    public static let memoryActive = "memory_active"
    public static let memoryInactive = "memory_inactive"
    public static let memoryCompressed = "memory_compressed"
    public static let memoryWired = "memory_wired"
    public static let physicalMemory = "memory_physical"
    public static let orientation = "device_orientation"
    public static let fullOrientation = "device_orientation_extended"
    public static let osBuild = "os_build"
    public static let osVersion = "os_version"
    public static let osName = "os_name"
    public static let resolution = "device_resolution"
    public static let carrier = "network_name"
    public static let carrierMNC = "network_mnc"
    public static let carrierMCC = "network_mcc"
    public static let carrierISO = "network_iso_country_code"
    public static let connectionType = "network_connection_type"
}

public extension TealiumConfig {

    func isMemoryReportingEnabled() -> Bool {
        if let enabled = self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] as? Bool {
            return enabled
        }

        // Default
        return false

    }

    func setMemoryReportingEnabled(_ enabled: Bool) {
        self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] = enabled
    }

}
