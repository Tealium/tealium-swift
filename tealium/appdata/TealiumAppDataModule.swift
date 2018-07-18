//
//  TealiumAppDataModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS
public enum TealiumAppDataKey {
    public static let moduleName = "appdata"
    public static let build = "app_build"
    public static let name = "app_name"
    public static let rdns = "app_rdns"
    public static let uuid = "app_uuid"
    public static let version = "app_version"
    public static let visitorId = "tealium_visitor_id"
}

// MARK: 
// MARK: MODULE SUBCLASS

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

        // Little wonky here because what if a persistence modules is still in the
        //  process of returning data?
        isEnabled = true

        // We're not going to wait for the loadrequest to return because it may never
        //  if there are no persistence modules enabled.
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        appData.deleteAllData()
        isEnabled = false

        didFinish(request)
    }

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
}

extension TealiumAppDataModule: TealiumSaveDelegate {
    func savePersistentData(data: [String: Any]) {
        let saveRequest = TealiumSaveRequest(name: TealiumAppDataModule.moduleConfig().name,
                                             data: data)

        delegate?.tealiumModuleRequests(module: self,
                                        process: saveRequest)
    }
}
