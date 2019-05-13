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

    required public init(delegate: TealiumModuleDelegate?) {
        super.init(delegate: delegate)
        appData = TealiumAppData(delegate: self)
    }

    init(delegate: TealiumModuleDelegate?, appData: TealiumAppDataProtocol) {
        super.init(delegate: delegate)
        self.appData = appData
    }

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAppDataKey.moduleName,
                                   priority: 500,
                                   build: 3,
                                   enabled: true)
    }

    /// Enables the module and loads AppData into memory
    ///
    /// - Parameter request: TealiumEnableRequest - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        let loadRequest = TealiumLoadRequest(name: TealiumAppDataModule.moduleConfig().name) { [weak self] _, data, _ in

            // No prior saved data
            guard let loadedData = data else {
                self?.appData.setNewAppData()
                return
            }

            // Loaded data does not contain expected keys
            if TealiumAppData.isMissingPersistentKeys(data: loadedData) == true {
                self?.appData.setNewAppData()
                return
            }

            self?.appData.setLoadedAppData(data: loadedData)
        }

        delegate?.tealiumModuleRequests(module: self,
                                        process: loadRequest)

        isEnabled = true

        // We're not going to wait for the loadrequest to return because it may never
        // if there are no persistence modules enabled.
        didFinish(request)
    }

    /// Adds current AppData to the track request
    ///
    /// - Parameter track: TealiumTrackRequest to be modified
    override func track(_ track: TealiumTrackRequest) {
        if isEnabled == false {
            // Ignore this module
            didFinishWithNoResponse(track)
            return
        }

        // If no persistence modules enabled.
        if TealiumAppData.isMissingPersistentKeys(data: appData.getData()) {
            appData.setNewAppData()
        }

        // Populate data stream
        var newData = [String: Any]()
        newData += appData.getData()
        newData += track.data

        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)

        didFinish(newTrack)
    }

    /// Disables the module and deletes all associated data
    ///
    /// - Parameter request: TealiumDisableRequest
    override func disable(_ request: TealiumDisableRequest) {
        appData.deleteAllData()
        isEnabled = false

        didFinish(request)
    }
}
