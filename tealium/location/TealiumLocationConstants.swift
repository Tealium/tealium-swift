//
//  TealiumLocationConstants.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation

public enum TealiumLocationKey {
    static let name = "TealiumLocationModule"
    static let dleBaseUrl = "https://tags.tiqcdn.com/dle/"
    static let fileName = "geofences"
    static let entered = "geofence_entered"
    static let exited = "geofence_exited"
    static let geofenceName = "geofence_name"
    static let geofenceTransition = "geofence_transition_type"
    static let deviceLatitude = "latitude"
    static let deviceLongitude = "longitude"
    static let timestamp = "location_timestamp"
    static let speed = "movement_speed"
    static let accuracy = "location_accuracy"
    static let additionRange = 500.0
    static let highAccuracy = "high"
    static let lowAccuracy = "low"
}

public enum TealiumLocationConfigKey {
    static let useHighAccuracy = "is_high_accuracy"
    static let updateDistance = "update_distance"
    static let geofenceAssetName = "geofence_asset_name"
    static let geofenceJsonUrl = "geofence_json_url"
}

public enum TealiumLocationConfig {
    case tealium
    case localFile(String)
    case customUrl(String)
}

public enum TealiumLocationErrors: String {
    case noUrl = "URL is empty."
    case noJson = "JSON is empty."
    case invalidUrl = "URL is invalid."
    case noFile = "File does not exist."
    case couldNotRetrieve = "Could not retrieve JSON."
    case couldNotDecode = "Could not decode JSON."
}
#endif
