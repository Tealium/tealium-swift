//
//  TealiumLocationExtensions.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
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

    /// Adds desired location accuracy to the Config instance
    /// Gets the current high accuracy setting
    ///
    /// - `Bool` true if high accuracy location updates are wanted,
    /// else false for lower accuracy location updates (more battery friendly)
    var useHighAccuracy: Bool {
        get {
            optionalData[TealiumLocationConfigKey.useHighAccuracy] as? Bool ?? false
        }
        
        set {
            optionalData[TealiumLocationConfigKey.useHighAccuracy] = newValue
        }
    }
    
    /// Sets the distance at which location updates should be received, e.g. 500.0 for every 500 meters
    /// Gets desired update distance from the Config instance
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
    
    /// Sets the name of the local file to be read that contains geofence json data
    /// Gets the name of the local file to read geofence data from
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
    
    /// Sets the url to be read that contains geofence json data
    /// Gets the url to read geofence data from
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
    
    /// Sets the String to be read that contains geofence json data
    /// Gets the url to read geofence data from
    ///
    /// - `String` String to read
    var geofenceJsonString: String? {
        get {
            optionalData[TealiumLocationConfigKey.geofenceJsonString] as? String
        }
        
        set {
            optionalData[TealiumLocationConfigKey.geofenceJsonString] = newValue
        }
    }
    
    /// Handles whether TealiumLocation requests location permission on behalf of the app.
    /// Gets the result of whether TealiumLocation should request location permission on behalf of the app.
    ///
    /// - `Bool` String to read
    var shouldRequestPermission: Bool {
        get {
            optionalData[TealiumLocationConfigKey.shouldRequestLocationPermission] as? Bool ?? true
        }
        
        set {
            optionalData[TealiumLocationConfigKey.shouldRequestLocationPermission] = newValue
        }
    }
    
    
    /// `TealiumLocationConfig`: The Geofences data retrieved from either a local file, url, or DLE 
    var initializeGeofenceDataFrom: TealiumLocationConfig {
        if let geofenceAsset = self.geofenceFileName {
            return .localFile(geofenceAsset)
        } else if let geofenceUrl = self.geofenceUrl {
            return .customUrl(geofenceUrl)
        } else if let geofenceString = self.geofenceJsonString {
            return .json(geofenceString)
        }
        return .tealium
    }
}
