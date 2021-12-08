//
//  TealiumLocationExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
#if location
import TealiumCore
#endif

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

extension TealiumConfigKey {
    static let desiredAccuracy = "desired_accuracy"
    static let updateDistance = "update_distance"
    static let useHighAccuracy = "is_high_accuracy"
    static let geofenceAssetName = "geofence_asset_name"
    static let geofenceJsonUrl = "geofence_json_url"
    static let geofenceTrackingEnabled = "geofence_tracking_enabled"
}

public extension TealiumConfig {

    /// The desired accuracy of the user's location collection
    ///
    /// - `LocationAccuracy` Default is `.reduced` in order to keep the user's privacy uppermost in mind. If using the geofence feature it would be beneficial to set to a higher accuracy level.
    /// Usage: `config.desiredAccuracy = .high`
    var desiredAccuracy: LocationAccuracy {
        get {
            options[TealiumConfigKey.desiredAccuracy] as? LocationAccuracy ?? .reduced
        }

        set {
            options[TealiumConfigKey.desiredAccuracy] = newValue
        }
    }

    /// The distance at which location updates should be received, e.g. 500.0 for every 500 meters. Default is `500.0`
    ///
    /// - `Double` distance in meters
    /// Usage: `config.updateDistance = 100.0`
    var updateDistance: Double {
        get {
            options[TealiumConfigKey.updateDistance] as? Double ?? 500.0
        }

        set {
            options[TealiumConfigKey.updateDistance] = newValue
        }
    }

    /// The name of the local file to be read that contains geofence json data. Default is `nil`
    ///
    /// - `String` name of local file to read
    /// Usage: `config.geofenceFileName = "geofences"`
    var geofenceFileName: String? {
        get {
            options[TealiumConfigKey.geofenceAssetName] as? String
        }

        set {
            options[TealiumConfigKey.geofenceAssetName] = newValue
        }
    }

    /// The url to be read that contains geofence json data
    ///
    /// - `String` name of the url to read. Default is `nil`
    /// Usage: `config.geofenceUrl = "https://yourserver.com/location/geofences.json"`
    var geofenceUrl: String? {
        get {
            options[TealiumConfigKey.geofenceJsonUrl] as? String
        }

        set {
            options[TealiumConfigKey.geofenceJsonUrl] = newValue
        }
    }

    /// Geofencing feature enabled true/false. If false, only lat/long and accuracy will be tracked
    ///
    /// - `Bool` Geofencing feature enabled, default is `true`
    /// Usage: `config.geofenceTrackingEnabled = false`
    var geofenceTrackingEnabled: Bool {
        get {
            options[TealiumConfigKey.geofenceTrackingEnabled] as? Bool ?? true
        }
        set {
            options[TealiumConfigKey.geofenceTrackingEnabled] = newValue
        }
    }

    /// `LocationConfig`: The Geofences data retrieved from either a local file, url, or DLE. Default is DLE
    /// Usage: `config.initializeGeofenceDataFrom = .localFile("geofences.json")`
    var initializeGeofenceDataFrom: LocationConfig? {
        guard geofenceTrackingEnabled else {
            return nil
        }
        if let geofenceAsset = self.geofenceFileName {
            return .localFile(geofenceAsset)
        } else if let geofenceUrl = self.geofenceUrl {
            return .customUrl(geofenceUrl)
        }
        return .tealium
    }

    /// - `Bool` true if more frequent location updates are wanted (better for geofence tracking)
    /// or false if only significant location updates are desired (more battery friendly).
    /// If geofence tracking is enabled, the default for this property is true. If geofences are not enabled, the default for this property is false
    /// Usage: `config.useHighAccuracy = true`
    var useHighAccuracy: Bool {
        get {
            options[TealiumConfigKey.useHighAccuracy] as? Bool ?? geofenceTrackingEnabled
        }
        set {
            options[TealiumConfigKey.useHighAccuracy] = newValue
        }
    }

}
#endif
