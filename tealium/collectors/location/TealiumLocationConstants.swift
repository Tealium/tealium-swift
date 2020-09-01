//
//  TealiumLocationConstants.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 12/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

public enum LocationKey {
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

public enum LocationConfigKey {
    static let useHighAccuracy = "is_high_accuracy"
    static let updateDistance = "update_distance"
    static let geofenceAssetName = "geofence_asset_name"
    static let geofenceJsonUrl = "geofence_json_url"
}

public enum LocationConfig {
    case tealium
    case localFile(String)
    case customUrl(String)
}

enum LocationErrors {
    static let noUrl = "URL is empty."
    static let noJson = "JSON is empty."
    static let invalidUrl = "URL is invalid."
    static let noFile = "File does not exist."
    static let couldNotRetrieve = "Could not retrieve JSON."
    static let couldNotDecode = "Could not decode JSON."
}
#endif
