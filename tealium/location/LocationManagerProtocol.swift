//
//  LocationManagerProtocol.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 10/09/2019.
//  Copyright © 2019 Harry Cassell. All rights reserved.
//
#if os(iOS)
import Foundation
import CoreLocation

public protocol LocationManager {
    static func locationServicesEnabled() -> Bool
    static func authorizationStatus() -> CLAuthorizationStatus
    var distanceFilter: Double {get set}
    var desiredAccuracy: CLLocationAccuracy {get set}
    var delegate: CLLocationManagerDelegate? {get set}
    var monitoredRegions: Set<CLRegion> {get}
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
