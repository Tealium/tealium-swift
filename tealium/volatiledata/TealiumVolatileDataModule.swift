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

// MARK: CONSTANTS

public enum TealiumVolatileDataKey {
    static let moduleName = "volatiledata"
    static let random = "tealium_random"
    static let sessionId = "tealium_session_id"
    public static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestampLegacy = "event_timestamp_iso"
    static let timestamp = "timestamp"
    static let timestampLocalLegacy = "event_timestamp_local_iso"
    static let timestampLocal = "timestamp_local"
    static let timestampOffsetLegacy = "event_timestamp_offset_hours"
    static let timestampOffset = "timestamp_offset"
    static let timestampUnixMillisecondsLegacy = "event_timestamp_unix_millis"
    static let timestampUnixMilliseconds = "timestamp_unix_milliseconds"
    static let timestampUnixLegacy = "event_timestamp_unix"
    static let timestampUnix = "timestamp_unix"
}

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func volatileData() -> TealiumVolatileData? {
        guard let module = modulesManager.getModule(forName: TealiumVolatileDataKey.moduleName) as? TealiumVolatileDataModule else {
            return nil
        }

        return module.volatileData
    }
}

// MARK: 
// MARK: MODULE SUBCLASS

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
        if let request = request as? TealiumEnableRequest {
             enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumTrackRequest {
            track(request)
        } else if let request = request as? TealiumJoinTraceRequest {
            joinTrace(request: request)
        } else if let request = request as? TealiumLeaveTraceRequest {
            leaveTrace(request: request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config

        let currentStaticData: [String: Any] = [TealiumKey.account: config.account,
                                                TealiumKey.profile: config.profile,
                                                TealiumKey.environment: config.environment,
                                                TealiumKey.libraryName: TealiumValue.libraryName,
                                                TealiumKey.libraryVersion: TealiumValue.libraryVersion,
                                                TealiumVolatileDataKey.sessionId: TealiumVolatileData.newSessionId(),
        ]

        volatileData.add(data: currentStaticData)

        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        volatileData.deleteAllData()
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {
        var newData = [String: Any]()

        newData += track.data

        if volatileData.shouldRefreshSessionIdentifier() {
            volatileData.setSessionId(sessionId: TealiumVolatileData.newSessionId())
        }

        newData += volatileData.getData(currentData: newData)

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        didFinish(newTrack)
        volatileData.lastTrackEvent = Date()
    }

    /// Adds Trace ID to all outgoing track requests
    ///
    /// - Parameter request: TealiumJoinTraceRequest
    func joinTrace(request: TealiumJoinTraceRequest) {
        self.volatileData.add(data: [TealiumKey.traceId: request.traceId])
        didFinish(request)
    }

    /// Removes trace ID from outgoing track requests
    ///
    /// - Parameter request: TealiumLeaveTraceRequest
    func leaveTrace(request: TealiumLeaveTraceRequest) {
        self.volatileData.deleteData(forKeys: [TealiumKey.traceId])
        didFinish(request)
    }
}
