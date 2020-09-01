//
//  TealiumLocationExtensions.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if location
import TealiumCore
#endif

// MARK: EXTENSIONS
public extension Tealium {

    /// Returns a LocationModule instance
    ///
    /// - Returns: `LocationModule?` instance (nil if disabled)
    var location: LocationModule? {
        return (zz_internal_modulesManager?.modules.first { $0 is LocationModule }) as? LocationModule
    }
}

public extension Collectors {
    static let Location = LocationModule.self
}

public extension TealiumConfig {

    /// The desired location accuracy
    ///
    ///
    /// - `Bool` true if more frequent location updates are wanted,
    /// or false if only significant location updates are desired (more battery friendly)
    var useHighAccuracy: Bool {
        get {
            options[LocationConfigKey.useHighAccuracy] as? Bool ?? false
        }

        set {
            options[LocationConfigKey.useHighAccuracy] = newValue
        }
    }

    /// The distance at which location updates should be received, e.g. 500.0 for every 500 meters
    ///
    ///
    /// - `Double` distance in meters
    var updateDistance: Double {
        get {
            options[LocationConfigKey.updateDistance] as? Double ?? 500.0
        }

        set {
            options[LocationConfigKey.updateDistance] = newValue
        }
    }

    /// The name of the local file to be read that contains geofence json data
    ///
    ///
    /// - `String` name of local file to read
    var geofenceFileName: String? {
        get {
            options[LocationConfigKey.geofenceAssetName] as? String
        }

        set {
            options[LocationConfigKey.geofenceAssetName] = newValue
        }
    }

    /// The url to be read that contains geofence json data
    ///
    ///
    /// - `String` name of the url to read
    var geofenceUrl: String? {
        get {
            options[LocationConfigKey.geofenceJsonUrl] as? String
        }

        set {
            options[LocationConfigKey.geofenceJsonUrl] = newValue
        }
    }

    /// `LocationConfig`: The Geofences data retrieved from either a local file, url, or DLE
    var initializeGeofenceDataFrom: LocationConfig {
        if let geofenceAsset = self.geofenceFileName {
            return .localFile(geofenceAsset)
        } else if let geofenceUrl = self.geofenceUrl {
            return .customUrl(geofenceUrl)
        }
        return .tealium
    }
}
#endif
