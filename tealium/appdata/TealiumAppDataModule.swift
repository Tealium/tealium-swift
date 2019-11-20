//
//  TealiumAppDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if appdata
import TealiumCore
#endif

/// Module to add app related data to track calls.
class TealiumAppDataModule: TealiumModule {

    var appData: TealiumAppDataProtocol!
    var diskStorage: TealiumDiskStorageProtocol!

    required public init(delegate: TealiumModuleDelegate?) {
        super.init(delegate: delegate)
    }

    init(delegate: TealiumModuleDelegate?,
         appData: TealiumAppDataProtocol) {
        super.init(delegate: delegate)
        self.appData = appData
    }

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAppDataKey.moduleName,
                                   priority: 500,
                                   build: 3,
                                   enabled: true)
    }

    /// Enable function required by TealiumModule.
    override func enable(_ request: TealiumEnableRequest) {
        self.enable(request, diskStorage: nil)
    }

    /// Enables the module and loads AppData into memory￼￼￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumEnableRequest` - the request from the core library to enable this module￼￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing
    func enable(_ request: TealiumEnableRequest,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        // allows overriding for unit tests, indepdendently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumAppDataKey.moduleName, isCritical: true)
        }
        self.appData = self.appData ?? TealiumAppData(diskStorage: self.diskStorage, existingVisitorId: request.config.getExistingVisitorId())
        isEnabled = true

        didFinish(request)
    }

    /// Adds current AppData to the track request￼￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be modified
    override func track(_ track: TealiumTrackRequest) {
        guard isEnabled else {
            // Ignore this module
            didFinishWithNoResponse(track)
            return
        }

        // do not add data to queued hits
        guard track.trackDictionary[TealiumKey.wasQueued] as? String == nil else {
            didFinishWithNoResponse(track)
            return
        }

        // Populate data stream
        var newData = [String: Any]()
        newData += appData.getData()
        newData += track.trackDictionary

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)

        didFinish(newTrack)
    }

    /// Disables the module and deletes all associated data￼￼.
    /// 
    /// - Parameter request: `TealiumDisableRequest`
    override func disable(_ request: TealiumDisableRequest) {
        if appData != nil {
            appData.deleteAllData()
        }
        isEnabled = false
        appData = nil
        diskStorage = nil
        didFinish(request)
    }
}
