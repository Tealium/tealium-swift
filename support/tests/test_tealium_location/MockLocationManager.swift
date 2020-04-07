//
//  MockLocationManager.swift
//  HarryDemoAppTests
//
//  Created by Harry Cassell on 10/09/2019.
//  Copyright © 2019 Harry Cassell. All rights reserved.
//

import CoreLocation
import Foundation
import TealiumLocation

class MockLocationManager: LocationManager {

    var requestWhenInUseAuthorizationCount = 0
    var startUpdatingLocationCount = 0
    var startMonitoringSignificantLocationChangesCount = 0
    var stopUpdatingLocationCount = 0
    var startMonitoringCount = 0
    var stopMonitoringCount = 0

    static var authorizationStatusCount = 0

    var distanceFilter: Double

    var desiredAccuracy: CLLocationAccuracy

    weak var delegate: CLLocationManagerDelegate?

    var monitoredRegions: Set<CLRegion> = Set<CLRegion>()

    init?(distanceFilter: Double, locationAccuracy: CLLocationAccuracy, delegateClass: CLLocationManagerDelegate?) {

        guard distanceFilter > 0.0 else {
            return nil
        }
        self.distanceFilter = distanceFilter
        self.desiredAccuracy = locationAccuracy
        self.delegate = delegateClass

    }

    static func locationServicesEnabled() -> Bool {
        return true
    }

    static func authorizationStatus() -> CLAuthorizationStatus {
        authorizationStatusCount += 1
        return .authorizedAlways
    }

    func requestAlwaysAuthorization() {

    }

    func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingLocationCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCount += 1
    }

    func startMonitoringSignificantLocationChanges() {
        startMonitoringSignificantLocationChangesCount += 1
    }

    func stopMonitoring(for region: CLRegion) {
        stopMonitoringCount += 1
        monitoredRegions.remove(region)
    }

    func startMonitoring(for region: CLRegion) {
        startMonitoringCount += 1
        monitoredRegions.insert(region)
    }

}
