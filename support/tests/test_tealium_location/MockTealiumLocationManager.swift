//
//  MockTealiumLocationManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import CoreLocation
import Foundation
@testable import TealiumLocation

class MockTealiumLocaitonManager: TealiumLocationManagerProtocol {

    var createdGeofencesCallCount = 0
    var isAuthorizedCallCount = 0
    var isFullAccuracyCallCount = 0
    var lastLocationCallCount = 0
    var locationAccuracyCallCount = 0
    var monitoredGeofencesCallCount = 0
    var clearMonitoredGeofencesCallCount = 0
    var disableCallCount = 0
    var requestAuthorizationCallCount = 0
    var requestTemporaryFullAccuracyAuthorizationCallCount = 0
    var sendGeofenceTrackingEventCallCount = 0
    var startLocationUpdatesCallCount = 0
    var startMonitoringCallCount = 0
    var stopLocationUpdatesCallCount = 0
    var stopMonitoringCallCount = 0

    var createdGeofences: [String]? {
        createdGeofencesCallCount += 1
        return ["geofence"]
    }

    var isAuthorized: Bool {
        isAuthorizedCallCount += 1
        return true
    }

    var isFullAccuracy: Bool {
        isFullAccuracyCallCount += 1
        return true
    }

    var lastLocation: CLLocation? {
        get {
            lastLocationCallCount += 1
            return CLLocation()
        }
        set {

        }
    }

    var locationAccuracy: String {
        get {
            locationAccuracyCallCount += 1
            return ""
        }
        set {

        }
    }

    var monitoredGeofences: [String]? {
        monitoredGeofencesCallCount += 1
        return ["monitoredGeofences"]
    }

    func clearMonitoredGeofences() {
        clearMonitoredGeofencesCallCount += 1
    }

    func disable() {
        disableCallCount += 1
    }

    func requestAuthorization() {
        requestAuthorizationCallCount += 1
    }

    func requestTemporaryFullAccuracyAuthorization(purposeKey: String) {
        requestTemporaryFullAccuracyAuthorizationCallCount += 1
    }

    func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        sendGeofenceTrackingEventCallCount += 1
    }

    func startLocationUpdates() {
        startLocationUpdatesCallCount += 1
    }

    func startMonitoring(_ geofences: [CLCircularRegion]) {
        startMonitoringCallCount += 1
    }

    func stopLocationUpdates() {
        stopLocationUpdatesCallCount += 1
    }

    func stopMonitoring(_ geofences: [CLCircularRegion]) {
        stopMonitoringCallCount += 1
    }

}
