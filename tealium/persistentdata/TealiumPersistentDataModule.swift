//
//  TealiumPersistentDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

#if persistentdata
import TealiumCore
#endif

/// Module for adding publicly accessible persistence data capability.
class TealiumPersistentDataModule: TealiumModule {

    var persistentData: TealiumPersistentData?
    var diskStorage: TealiumDiskStorageProtocol!

    override class func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumPersistentKey.moduleName,
                                    priority: 600,
                                    build: 2,
                                    enabled: true)
    }

    /// Enables the module
    ///
    /// - Parameter request: `TealiumEnableRequest` from which to enable the module
    override func enable(_ request: TealiumEnableRequest) {
        self.enable(request, diskStorage: nil)
    }

    /// Enables the module and loads PersistentData into memory￼￼￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumEnableRequest` - the request from the core library to enable this module￼￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing
    func enable(_ request: TealiumEnableRequest,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        isEnabled = true
        // allows overriding for unit tests, indepdendently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumPersistentKey.moduleName, isCritical: true)
        }
        self.persistentData = TealiumPersistentData(diskStorage: self.diskStorage)
        didFinish(request)
    }

    /// Disables the module and deletes all associated data￼￼.
    ///
    /// - Parameter request: `TealiumDisableRequest`
    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        persistentData?.deleteAllData()
        persistentData = nil
        didFinish(request)
    }

    /// Adds current Persistent data to the track request￼￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be modified
    override func track(_ track: TealiumTrackRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(track)
            return
        }

        guard let persistentData = self.persistentData else {
            // Unable to load persistent data - continue with track call
            didFinish(track)
            return
        }

        guard persistentData.persistentDataCache.isEmpty == false else {
            // No custom persistent data to load
            didFinish(track)
            return
        }

        guard let data = persistentData.persistentDataCache.values() else {
            didFinish(track)
            return
        }

        var dataDictionary = [String: Any]()

        dataDictionary += data
        dataDictionary += track.trackDictionary
        let newTrack = TealiumTrackRequest(data: dataDictionary,
                                           completion: track.completion)

        didFinish(newTrack)
    }
}
