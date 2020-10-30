//
//  MockLocationManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import CoreLocation
import Foundation
import TealiumCore
import TealiumLocation

class MockLocationManager: LocationManagerProtocol {

    static var authorizationStatusCount = 0
    var accuracyAuthorizationCallCount = 0
    var requestAlwaysAuthorizationCount = 0
    var requestWhenInUseAuthorizationCount = 0
    var requestTemporaryFullAccuracyAuthorizationCount = 0
    var startUpdatingLocationCount = 0
    var startMonitoringSignificantLocationChangesCount = 0
    var stopUpdatingLocationCount = 0
    var startMonitoringCount = 0
    var stopMonitoringCount = 0

    var activityType: CLActivityType = .other
    weak var delegate: CLLocationManagerDelegate?
    var desiredAccuracy: CLLocationAccuracy = 1
    var distanceFilter: Double
    static var enableLocationServices = false
    var monitoredRegions: Set<CLRegion> = Set<CLRegion>()
    var pausesLocationUpdatesAutomatically: Bool = true

    init?(config: TealiumConfig, enableServices: Bool = false, delegateClass: CLLocationManagerDelegate?) {

        self.distanceFilter = config.updateDistance
        guard distanceFilter > 0.0 else {
            return nil
        }
        self.delegate = delegateClass
        MockLocationManager.enableLocationServices = enableServices
    }

    var accuracyAuthorization: CLAccuracyAuthorization {
        accuracyAuthorizationCallCount += 1
        return .reducedAccuracy
    }

    static func locationServicesEnabled() -> Bool {
        return true
    }

    static func authorizationStatus() -> CLAuthorizationStatus {
        authorizationStatusCount += 1
        guard enableLocationServices else {
            return .notDetermined
        }
        return .authorizedAlways
    }

    func requestAlwaysAuthorization() {
        requestAlwaysAuthorizationCount += 1
    }

    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String, completion: ((Error?) -> Void)?) {
        requestTemporaryFullAccuracyAuthorizationCount += 1
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
