//
//  TealiumAttributionModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if attribution
import TealiumCore
#endif

class TealiumAttributionModule: TealiumModule {

    var attributionData: TealiumAttributionDataProtocol!
    var diskStorage: TealiumDiskStorageProtocol!

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAttributionKey.moduleName,
                                   priority: 400,
                                   build: 3,
                                   enabled: true)
    }

    /// Provided for unit testing￼.
    ///
    /// - Parameter attributionData: Class instance conforming to `TealiumAttributionDataProtocol`
    convenience init (attributionData: TealiumAttributionDataProtocol) {
        self.init(delegate: nil)
        self.attributionData = attributionData
    }

    /// Module init￼.
    ///
    /// - Parameter delegate: `TealiumModuleDelegate?`
    required public init(delegate: TealiumModuleDelegate?) {
        super.init(delegate: delegate)
    }

    /// Enable function required by TealiumModule.
    override func enable(_ request: TealiumEnableRequest) {
        self.enable(request, diskStorage: nil)
    }

    /// Enables the module and loads persistent attribution data into memory￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumEnableRequest` - the request from the core library to enable this module￼
    ///     - diskStorage: `TealiumDiskStorageProtocol` instance to allow overriding for unit testing
    func enable(_ request: TealiumEnableRequest,
                diskStorage: TealiumDiskStorageProtocol? = nil) {
        // allows overriding for unit tests, indepdendently of enable call
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumAttributionKey.moduleName)
        }
        self.attributionData = TealiumAttributionData(diskStorage: self.diskStorage,
                                                      isSearchAdsEnabled: request.config.searchAdsEnabled)
        isEnabled = true
        if !request.bypassDidFinish {
            didFinish(request)
        }
    }

    override func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.diskStorage = TealiumDiskStorage(config: request.config, forModule: TealiumAttributionKey.moduleName)
            self.attributionData = TealiumAttributionData(diskStorage: self.diskStorage,
                                                          isSearchAdsEnabled: request.config.searchAdsEnabled)
        }
        self.config = newConfig
        didFinish(request)
    }

    /// Adds current AttributionData to the track request￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be modified
    override func track(_ track: TealiumTrackRequest) {
        // Add idfa to data - NOTE: You must tell Apple why you are using this data when
        // submitting your app for review. See:
        // https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8

        guard isEnabled else {
            // Module disabled - ignore request
            didFinish(track)
            return
        }
        let track = addModuleName(to: track)
        // do not add data to queued hits
        guard track.trackDictionary[TealiumKey.wasQueued] as? String == nil else {
            didFinishWithNoResponse(track)
            return
        }

        // Module enabled - add attribution info to data
        var newData = track.trackDictionary
        newData += attributionData.allAttributionData

        var newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        newTrack.moduleResponses = track.moduleResponses

        didFinish(newTrack)
    }
    

    /// Disables the module and deletes all associated data￼.
    /// 
    /// - Parameter request: `TealiumDisableRequest`
    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        if diskStorage != nil {
            diskStorage.delete(completion: nil)
            diskStorage = nil
        }
        didFinish(request)
    }
}
