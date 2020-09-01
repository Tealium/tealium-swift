//
//  LocationManagerProtocols.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 10/09/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//
#if os(iOS)
import CoreLocation
import Foundation

public protocol TealiumLocationManagerProtocol {
    var createdGeofences: [String]? { get }
    var lastLocation: CLLocation? { get }
    var locationAccuracy: String { get set }
    var locationServiceEnabled: Bool { get }
    var monitoredGeofences: [String]? { get }
    func clearMonitoredGeofences()
    func disable()
    func requestAuthorization()
    func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String)
    func startLocationUpdates()
    func startMonitoring(_ geofences: [CLCircularRegion])
    func stopLocationUpdates()
    func stopMonitoring(_ geofences: [CLCircularRegion])
}

public protocol LocationManager {
    static func locationServicesEnabled() -> Bool
    static func authorizationStatus() -> CLAuthorizationStatus
    var distanceFilter: Double { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var monitoredRegions: Set<CLRegion> { get }
    func requestAlwaysAuthorization()
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoringSignificantLocationChanges()
    func stopMonitoring(for region: CLRegion)
    func startMonitoring(for region: CLRegion)
}

extension CLLocationManager: LocationManager { }
#endif
