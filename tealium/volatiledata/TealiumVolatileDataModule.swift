//
//  TealiumVolatileDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if volatiledata
import TealiumCore
#endif

/// Module for adding session long (from wake until terminate) data varables to all track calls.
class TealiumVolatileDataModule: TealiumModule {

    var volatileData = TealiumVolatileData()

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumVolatileDataKey.moduleName,
                                   priority: 700,
                                   build: 3,
                                   enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)

        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            track(request)
        case let request as TealiumJoinTraceRequest:
            joinTrace(request)
        case let request as TealiumLeaveTraceRequest:
            leaveTrace(request)
        case let request as TealiumUpdateConfigRequest:
            updateConfig(request)
        default:
            didFinishWithNoResponse(request)
        }
    }

    /// Enables the module and sets up volatile data instance.
    ///￼
    /// - Parameter request: `TealiumDisableRequest
    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config

        var currentStaticData = [TealiumKey.account: config.account,
                                                TealiumKey.profile: config.profile,
                                                TealiumKey.environment: config.environment,
                                                TealiumKey.libraryName: TealiumValue.libraryName,
                                                TealiumKey.libraryVersion: TealiumValue.libraryVersion,
                                                TealiumKey.sessionId: TealiumVolatileData.newSessionId(),
        ]

        if let dataSource = config.datasource {
            currentStaticData[TealiumKey.dataSource] = dataSource
        }

        volatileData.add(data: currentStaticData)

        if !request.bypassDidFinish {
            didFinishWithNoResponse(request)
        }
    }

    override func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            var enableRequest = TealiumEnableRequest(config: newConfig, enableCompletion: nil)
            enableRequest.bypassDidFinish = true
            enable(enableRequest)
        }
        didFinish(request)
    }

    /// Disables the module and deletes all volatile data.
    ///￼
    /// - Parameter request: `TealiumDisableRequest`
    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        volatileData.deleteAllData()
        didFinish(request)
    }

    /// Adds volatile data to all track requests.
    ///￼
    /// - Parameter track: `TealiumTrackRequest`
    override func track(_ track: TealiumTrackRequest) {
        let track = addModuleName(to: track)
        var newData = [String: Any]()

        newData += track.trackDictionary

        if volatileData.shouldRefreshSessionIdentifier() {
            volatileData.setSessionId(sessionId: TealiumVolatileData.newSessionId())
        }

        newData += volatileData.getData(currentData: newData)

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        didFinishWithNoResponse(newTrack)
        volatileData.lastTrackEvent = Date()
    }

    /// Adds Trace ID to all outgoing track requests.
    ///￼
    /// - Parameter request: `TealiumJoinTraceRequest`
    func joinTrace(_ request: TealiumJoinTraceRequest) {
        self.volatileData.add(data: [TealiumKey.traceId: request.traceId])
        didFinish(request)
    }

    /// Removes trace ID from outgoing track requests.
    ///￼
    /// - Parameter request: `TealiumLeaveTraceRequest`
    func leaveTrace(_ request: TealiumLeaveTraceRequest) {
        self.volatileData.deleteData(forKeys: [TealiumKey.traceId])
        didFinish(request)
    }
}
