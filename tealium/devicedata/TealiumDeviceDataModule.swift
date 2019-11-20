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

#if devicedata
import TealiumCore
#endif

import Darwin

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
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumTrackRequest:
            track(request)
        default:
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
        guard isEnabled else {
            return
        }

        // do not add data to queued hits
        guard request.trackDictionary[TealiumKey.wasQueued] as? String == nil else {
            didFinishWithNoResponse(request)
            return
        }

        // Add device data to the data stream.
        var newData = request.trackDictionary
        newData += data
        newData += trackTimeData()
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: request.completion)

        didFinish(newTrack)
    }

    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: `[String:Any]` of enable-time device data.
    func enableTimeData() -> [String: Any] {
        var result = [String: Any]()

        result[TealiumKey.architectureLegacy] = deviceDataCollection.architecture()
        result[TealiumKey.architecture] = result[TealiumKey.architectureLegacy] ?? ""
        result[TealiumDeviceDataKey.osBuildLegacy] = TealiumDeviceData.oSBuild()
        result[TealiumDeviceDataKey.osBuild] = TealiumDeviceData.oSBuild()
        result[TealiumKey.cpuTypeLegacy] = deviceDataCollection.cpuType()
        result[TealiumKey.cpuType] = result[TealiumKey.cpuTypeLegacy] ?? ""
        result.merge(deviceDataCollection.model()) { _, new -> Any in
            new
        }
        result[TealiumDeviceDataKey.osVersionLegacy] = TealiumDeviceData.oSVersion()
        result[TealiumDeviceDataKey.osVersion] = result[TealiumDeviceDataKey.osVersionLegacy] ?? ""
        result[TealiumKey.osName] = TealiumDeviceData.oSName()
        result[TealiumKey.platform] = result[TealiumKey.osName] ?? ""
        result[TealiumKey.resolution] = TealiumDeviceData.resolution()
        return result
    }

    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: `[String: Any]` of track-time device data.
    func trackTimeData() -> [String: Any] {
        var result = [String: Any]()

        result[TealiumDeviceDataKey.batteryPercentLegacy] = TealiumDeviceData.batteryPercent()
        result[TealiumDeviceDataKey.batteryPercent] = result[TealiumDeviceDataKey.batteryPercentLegacy] ?? ""
        result[TealiumDeviceDataKey.isChargingLegacy] = TealiumDeviceData.isCharging()
        result[TealiumDeviceDataKey.isCharging] = result[TealiumDeviceDataKey.isChargingLegacy] ?? ""
        result[TealiumKey.languageLegacy] = TealiumDeviceData.iso639Language()
        result[TealiumKey.language] = result[TealiumKey.languageLegacy] ?? ""
        if isMemoryEnabled {
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
