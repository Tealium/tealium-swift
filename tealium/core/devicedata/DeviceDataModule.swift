//
//  DeviceDataModule.swift
//  tealium-swift
//
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

public class DeviceDataModule: Collector {
    public let id: String = ModuleNames.devicedata

    public var data: [String: Any]? {
        cachedData += trackTimeData
        return cachedData
    }

    var isMemoryReportingEnabled: Bool {
        config.memoryReportingEnabled
    }
    var deviceDataCollection: DeviceDataCollection
    var cachedData = [String: Any]()
    public var config: TealiumConfig

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ModuleCompletion) {
        self.config = context.config
        deviceDataCollection = DeviceData()
        cachedData = enableTimeData
        completion((.success(true), nil))
    }

    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: `[String:Any]` of enable-time device data.
    var enableTimeData: [String: Any] {
        var result = [String: Any]()

        result[TealiumKey.architecture] = deviceDataCollection.architecture()
        result[DeviceDataKey.osBuild] = DeviceData.oSBuild
        result[TealiumKey.cpuType] = deviceDataCollection.cpuType
        result += deviceDataCollection.model
        result[DeviceDataKey.osVersion] = DeviceData.oSVersion
        result[TealiumKey.osName] = DeviceData.oSName
        result[TealiumKey.platform] = (result[TealiumKey.osName] as? String ?? "").lowercased()
        result[TealiumKey.resolution] = DeviceData.resolution
        return result
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: `[String: Any]` of track-time device data.
    var trackTimeData: [String: Any] {
        var result = [String: Any]()

        result[DeviceDataKey.batteryPercent] = DeviceData.batteryPercent
        result[DeviceDataKey.isCharging] = DeviceData.isCharging
        result[TealiumKey.language] = DeviceData.iso639Language
        if isMemoryReportingEnabled {
            result += deviceDataCollection.memoryUsage
        }
        result += deviceDataCollection.orientation
        result += DeviceData.carrierInfo
        return result
    }
}
