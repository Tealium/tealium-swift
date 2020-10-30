//
//  TealiumLocationConstants.swift
//  tealium-swift
//
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
    static let accuracyExtended = "location_accuracy_extended"
    static let additionRange = 500.0
    static let highAccuracy = "high"
    static let lowAccuracy = "low"
}

public enum LocationConfigKey {
    static let desiredAccuracy = "desired_accuracy"
    static let updateDistance = "update_distance"
    static let useHighAccuracy = "is_high_accuracy"
    static let geofenceAssetName = "geofence_asset_name"
    static let geofenceJsonUrl = "geofence_json_url"
    static let geofenceTrackingEnabled = "geofence_tracking_enabled"
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

public enum LocationAccuracy: String {
    case bestForNavigation = "best_for_navigation"
    case best
    case nearestTenMeters = "nearest_ten_meters"
    case nearestHundredMeters = "nearest_hundred_meters"
    case reduced
    case withinOneKilometer = "within_one_kilometer"
    case withinThreeKilometers = "within_three_kilometers"
}

#endif
