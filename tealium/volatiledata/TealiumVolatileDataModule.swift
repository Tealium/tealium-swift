//
//  TealiumVolatileDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

public enum TealiumVolatileDataKey {
    static let moduleName = "volatiledata"
    static let random = "tealium_random"
    static let sessionId = "tealium_session_id"
    public static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestamp = "event_timestamp_iso"
    static let timestampLocal = "event_timestamp_local_iso"
    static let timestampOffset = "event_timestamp_offset_hours"
    static let timestampUnix = "event_timestamp_unix_millis"
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

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config

        let currentStaticData: [String: Any] = [TealiumKey.account: config.account,
                                                TealiumKey.profile: config.profile,
                                                TealiumKey.environment: config.environment,
                                                TealiumKey.libraryName: TealiumValue.libraryName,
                                                TealiumKey.libraryVersion: TealiumValue.libraryVersion,
                                                TealiumVolatileDataKey.sessionId: TealiumVolatileData.newSessionId()]

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

        newData += volatileData.getData()

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        didFinish(newTrack)
        volatileData.lastTrackEvent = Date()
    }
}
