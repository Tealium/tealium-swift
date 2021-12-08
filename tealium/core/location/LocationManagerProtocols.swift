//
//  LocationManagerProtocols.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//
#if os(iOS) && !targetEnvironment(macCatalyst)
import CoreLocation
import Foundation

public protocol TealiumLocationManagerProtocol {
    var createdGeofences: [String]? { get }
    var isAuthorized: Bool { get }
    @available(iOS 14.0, *)
    var isFullAccuracy: Bool { get }
    var lastLocation: CLLocation? { get set }
    var locationAccuracy: String { get set }
    var monitoredGeofences: [String]? { get }
    func clearMonitoredGeofences()
    func disable()
    func requestAuthorization()
    @available(iOS 14, *)
    func requestTemporaryFullAccuracyAuthorization(purposeKey: String)
    func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String)
    func startLocationUpdates()
    func startMonitoring(_ geofences: [CLCircularRegion])
    func stopLocationUpdates()
    func stopMonitoring(_ geofences: [CLCircularRegion])
}

public protocol LocationManagerProtocol {
    @available(iOS 14, *)
    var accuracyAuthorization: CLAccuracyAuthorization { get }
    var activityType: CLActivityType { get set }
    static func authorizationStatus() -> CLAuthorizationStatus
    var distanceFilter: Double { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var monitoredRegions: Set<CLRegion> { get }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()
    @available(iOS 14, *)
    func requestTemporaryFullAccuracyAuthorization(withPurposeKey purposeKey: String,
                                                   completion: ((Error?) -> Void)?)
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoring(for region: CLRegion)
    func startMonitoring(for region: CLRegion)
}

extension CLLocationManager: LocationManagerProtocol { }
#endif
