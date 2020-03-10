//
//  TealiumLocation.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 02/09/2019.
//  Updated by Christina Sund on 1/13/2020.
//  Copyright © 2019 Harry Cassell. All rights reserved.
//

import Foundation
import CoreLocation
#if location
    import TealiumCore
#endif

public class TealiumLocation: NSObject, CLLocationManagerDelegate {
    var config: TealiumConfig
    var locationManager: LocationManager
    var lastLocation: CLLocation?
    var geofences = Geofences()
    var locationListener: LocationListener?
    var logger: TealiumLogger?
    var didEnterRegionWorking = false
    
    init(config: TealiumConfig,
        bundle: Bundle = Bundle.main,
        locationListener: LocationListener? = nil,
        locationManager: LocationManager = CLLocationManager()) {
        self.config = config
        self.locationListener = locationListener
        self.locationManager = locationManager
        
        if let logLevel = config.logLevel {
            self.logger = TealiumLogger(loggerId: TealiumLocationKey.name, logLevel: logLevel)

        }
        
        super.init()
        
        switch config.initializeGeofenceDataFrom {
            case .localFile(let file):
                geofences = GeofenceData(file: file, bundle: bundle)?.geofences ?? Geofences()
            case .customUrl(let url):
                geofences = GeofenceData(url: url)?.geofences ?? Geofences()
            default:
                geofences = GeofenceData(url: geofencesUrl)?.geofences ?? Geofences()
                break
        }
        
        
        self.locationManager.distanceFilter = config.updateDistance
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        requestPermissions()
        clearMonitoredGeofences()
        startLocationUpdates()
    }
    
    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    ///
    /// - parameter config: `TealiumConfig` tealium config to be read from
    var geofencesUrl: String {
        return "\(TealiumLocationKey.dleBaseUrl)\(config.account)/\(config.profile)/\(TealiumLocationKey.fileName).json"
    }

    
    /// Gets the permission status of Location Services
    ///
    /// - return: `Bool` LocationManager services enabled true/false
    public var locationServiceEnabled: Bool {
        let permissionStatus = type(of: locationManager).self.authorizationStatus()
        guard (permissionStatus == .authorizedAlways || permissionStatus == .authorizedWhenInUse),
            type(of: locationManager).self.locationServicesEnabled() else {
            return false
        }
        return true
    }
    
    /// Prompts the user to enable permission for location servies
    public func requestPermissions() {
        let permissionStatus = type(of: locationManager).self.authorizationStatus()

        if permissionStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        
        if  permissionStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initisalizatuion of this class.
    public func startLocationUpdates() {
        guard locationServiceEnabled else {
            logInfo(message: "🌎🌎 Location Updates Service Not Enabled 🌎🌎")
            return
        }
        guard config.useHighAccuracy else {
            locationManager.startMonitoringSignificantLocationChanges()
            logInfo(message: "🌎🌎 Location Updates Significant Location Change Accuracy Started 🌎🌎")
            return
        }
        locationManager.startUpdatingLocation()
        logInfo(message: "🌎🌎 Location Updates High Accuracy Started 🌎🌎")
    }
    
    /// Stops the updating of location data through the location client.
    public func stopLocationUpdates() {
        guard locationServiceEnabled else {
            return
        }
        locationManager.stopUpdatingLocation()
        logInfo(message: "🌎🌎 Location Updates Stopped 🌎🌎")
    }
    
    /// CLLocationManagerDelegate method
    /// Updates a member variable containing the most recent device location alongisde
    /// updating the monitored geofences based on the users last location. (Dynamic Geofencing)
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter locations: `CLLocation` array of recent locations, includes most recent
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            self.lastLocation = lastLocation
        }
        logInfo(message: "🌎🌎 Location updated: \(String(describing: lastLocation?.coordinate)) 🌎🌎")
        geofences.regions.forEach {
            let geofenceLocation = CLLocation(latitude: $0.center.latitude, longitude: $0.center.longitude)
            
            guard let distance = lastLocation?.distance(from: geofenceLocation),
                distance.isLess(than: TealiumLocationKey.additionRange) else {
                stopMonitoring(geofence: $0)
                return
            }
            startMonitoring(geofence: $0)
        }
    }
    
    /// CLLocationManagerDelegate method
    /// If the location client encounters an error, location updates are stopped
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter error: `error` an error that has occured
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError,
            error.code == .denied {
            logger?.log(message: "🌎🌎 An error has occured: \(String(describing: error.localizedDescription)) 🌎🌎", logLevel: .errors)
            locationManager.stopUpdatingLocation()
        }
    }
    
    /// CLLocationManagerDelegate method
    /// Calls for the sending of a Tealium tracking calls on geofence enter and exit event
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter state: `CLRegionState` state of the device with reference to a region.
    /// - parameter region: `CLRegion` that was entered
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside && region.notifyOnEntry {
            sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.entered)
        } else if state == .outside && region.notifyOnExit {
            sendGeofenceTrackingEvent(region: region, triggeredTransition: TealiumLocationKey.exited)
        }
    }
    
    /// CLLocationManagerDelegate method
    /// Calls for the sending of a Tealium tracking calls on geofence enter and exit event
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter status: `CLAuthorizationStatus` authorization state of the application.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startLocationUpdates()
    }
    
    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occured
    public func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        var data = [String : Any]()
        data[TealiumLocationKey.geofenceName] = "\(region.identifier)"
        data[TealiumLocationKey.geofenceTransition] = triggeredTransition
        data[TealiumKey.event] = triggeredTransition
        
        if let lastLocation = lastLocation {
            data[TealiumLocationKey.latitude] = "\(lastLocation.coordinate.latitude)"
            data[TealiumLocationKey.longitude] = "\(lastLocation.coordinate.longitude)"
            data[TealiumLocationKey.timestamp] = "\(lastLocation.timestamp)"
            data[TealiumLocationKey.speed] = "\(lastLocation.speed)"
        }
        
        if triggeredTransition == TealiumLocationKey.exited {
            locationListener?.didExitGeofence(data)
        } else if triggeredTransition == TealiumLocationKey.entered {
            locationListener?.didEnterGeofence(data)
        }
    }
    
    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation` location object
    public var latestLocation: CLLocation {
        guard let lastLocation = lastLocation else {
            return CLLocation.init()
        }
        return lastLocation
    }
    
    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be added
    public func startMonitoring(geofences: Array<CLCircularRegion>) {
        if geofences.capacity == 0 {
            return
        }
        
        geofences.forEach {
            if !(locationManager.monitoredRegions.contains($0)) {
                locationManager.startMonitoring(for: $0)
            }
        }
    }
    
    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofence: `CLCircularRegion` Geofence to be added
    public func startMonitoring(geofence: CLCircularRegion) {
        if !locationManager.monitoredRegions.contains(geofence) {
            locationManager.startMonitoring(for: geofence)
            logInfo(message: "🌎🌎 \(geofence.identifier) Added to monitored client 🌎🌎")
        }
    }
    
    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofences: `Array<CLCircularRegion>` Geofences to be removed
    public func stopMonitoring(geofences: Array<CLCircularRegion>) {
        if geofences.capacity == 0 {
            return
        }
        
        geofences.forEach {
            if locationManager.monitoredRegions.contains($0) {
                locationManager.stopMonitoring(for: $0)
            }
        }
    }
    
    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofence: `CLCircularRegion` Geofence to be removed
    public func stopMonitoring(geofence: CLCircularRegion) {
        if locationManager.monitoredRegions.contains(geofence) {
            locationManager.stopMonitoring(for: geofence)
            logInfo(message: "🌎🌎 \(geofence.identifier) Removed from monitored client 🌎🌎")
        }
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - return: `[String]` Array containing the names of monitored geofences
    public var monitoredGeofences: [String]? {
        guard locationServiceEnabled else {
            return nil
        }
        return locationManager.monitoredRegions.map { $0.identifier }
    }
    
    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]` Array containing the names of all geofences
    public var createdGeofences: [String]? {
        guard locationServiceEnabled else {
            return nil
        }
        return geofences.map { $0.name }
    }
    
    /// Removes all geofences that are currently being monitored from the Location Client
    public func clearMonitoredGeofences() {
        locationManager.monitoredRegions.forEach {
            locationManager.stopMonitoring(for: $0)
        }
    }
    
    /// Stops location updates, Removes all active geofences from being monitored,
    /// and resets the array of created geofences
    public func disable() {
        stopLocationUpdates()
        clearMonitoredGeofences()
        self.geofences = Geofences()
    }
    
    /// Logs verbose information about events occuring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    func logInfo(message: String) {
        logger?.log(message: message, logLevel: .verbose)
    }

}

