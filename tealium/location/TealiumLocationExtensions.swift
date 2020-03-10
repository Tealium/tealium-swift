//
//  TealiumLocationExtensions.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if location
    import TealiumCore
#endif

// MARK: EXTENSIONS
public extension Tealium {

    /// Get the Data Manager instance for accessing file persistence and auto data variable APIs.
    ///
    /// - Returns: `TealiumLocation?` instance (nil if disabled)
    func location() -> TealiumLocation? {
        guard let module = modulesManager.getModule(forName: TealiumLocationKey.name) as? TealiumLocationModule else {
            return nil
        }

        return module.tealiumLocationManager
    }

}

public extension TealiumConfig {

    /// The desired location accuracy
    ///
    ///
    /// - `Bool` true if more frequent location updates are wanted,
    /// or false if only significant location updates are desired (more battery friendly)
    var useHighAccuracy: Bool {
        get {
            optionalData[TealiumLocationConfigKey.useHighAccuracy] as? Bool ?? false
        }
        
        set {
            optionalData[TealiumLocationConfigKey.useHighAccuracy] = newValue
        }
    }
    
    /// The distance at which location updates should be received, e.g. 500.0 for every 500 meters
    ///
    ///
    /// - `Double` distance in meters
    var updateDistance: Double {
        get {
            optionalData[TealiumLocationConfigKey.updateDistance] as? Double ?? 500.0
        }
        
        set {
            optionalData[TealiumLocationConfigKey.updateDistance] = newValue
        }
    }
    
    /// The name of the local file to be read that contains geofence json data
    ///
    ///
    /// - `String` name of local file to read
    var geofenceFileName: String? {
        get {
            optionalData[TealiumLocationConfigKey.geofenceAssetName] as? String
        }
        
        set {
            optionalData[TealiumLocationConfigKey.geofenceAssetName] = newValue
        }
    }
    
    /// The url to be read that contains geofence json data
    ///
    ///
    /// - `String` name of the url to read
    var geofenceUrl: String? {
        get {
            optionalData[TealiumLocationConfigKey.geofenceJsonUrl] as? String
        }
        
        set {
            optionalData[TealiumLocationConfigKey.geofenceJsonUrl] = newValue
        }
    }
    
    /// `TealiumLocationConfig`: The Geofences data retrieved from either a local file, url, or DLE 
    var initializeGeofenceDataFrom: TealiumLocationConfig {
        if let geofenceAsset = self.geofenceFileName {
            return .localFile(geofenceAsset)
        } else if let geofenceUrl = self.geofenceUrl {
            return .customUrl(geofenceUrl)
        }
        return .tealium
    }
}
