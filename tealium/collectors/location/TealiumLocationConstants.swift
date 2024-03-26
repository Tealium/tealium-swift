//
//  TealiumLocationConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation

#if location
import TealiumCore
#endif

public extension TealiumDataKey {
    static let deviceLatitude = "latitude"
    static let deviceLongitude = "longitude"
    static let locationAccuracy = "location_accuracy"
    static let locationAccuracyExtended = "location_accuracy_extended"
    static let geofenceName = "geofence_name"
    static let geofenceTransition = "geofence_transition_type"

    static let locationTimestamp = "location_timestamp"
    static let locationSpeed = "movement_speed"
}

public enum LocationKey {
    static let name = "TealiumLocationModule"
    static let fileName = "geofences"
    static let entered = "geofence_entered"
    static let exited = "geofence_exited"
    static let additionRange = 500.0
    static let highAccuracy = "high"
    static let lowAccuracy = "low"
}

public enum LocationConfig {
    case tealium
    case localFile(String)
    case customUrl(String)
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
