//
//  TealiumLocationManager.swift
//  TealiumLocation
//
//  Created by Harry Cassell on 02/09/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//
#if os(iOS)
import CoreLocation
import Foundation
#if location
import TealiumCore
#endif

public class TealiumLocationManager: NSObject, CLLocationManagerDelegate, TealiumLocationManagerProtocol {

    var config: TealiumConfig
    var logger: TealiumLoggerProtocol? {
        config.logger
    }
    var locationManager: LocationManager
    var geofences = Geofences()
    weak var locationDelegate: LocationDelegate?
    var didEnterRegionWorking = false
    public var locationAccuracy = LocationKey.lowAccuracy
    private var _lastLocation: CLLocation?

    init(config: TealiumConfig,
         bundle: Bundle = Bundle.main,
         locationDelegate: LocationDelegate? = nil,
         locationManager: LocationManager = CLLocationManager()) {
        self.config = config
        self.locationDelegate = locationDelegate
        self.locationManager = locationManager

        super.init()

        switch config.initializeGeofenceDataFrom {
        case .localFile(let file):
            geofences = GeofenceData(file: file, bundle: bundle, logger: config.logger)?.geofences ?? Geofences()
        case .customUrl(let url):
            geofences = GeofenceData(url: url, logger: config.logger)?.geofences ?? Geofences()
        default:
            geofences = GeofenceData(url: geofencesUrl, logger: config.logger)?.geofences ?? Geofences()
        }

        self.locationManager.distanceFilter = config.updateDistance
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if config.useHighAccuracy {
            locationAccuracy = LocationKey.highAccuracy
        }

        clearMonitoredGeofences()
    }

    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    var geofencesUrl: String {
        return "\(LocationKey.dleBaseUrl)\(config.account)/\(config.profile)/\(LocationKey.fileName).json"
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
    public func requestAuthorization() {
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
    /// - parameter locations: `[CLLocation]` array of recent locations, includes most recent
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            self.lastLocation = lastLocation
        }
        logInfo(message: "🌎🌎 Location updated: \(String(describing: lastLocation?.coordinate)) 🌎🌎")
        geofences.regions.forEach {
            let geofenceLocation = CLLocation(latitude: $0.center.latitude, longitude: $0.center.longitude)

            guard let distance = lastLocation?.distance(from: geofenceLocation),
                distance.isLess(than: config.updateDistance) else {
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
            logError(message: "🌎🌎 An error has occured: \(String(describing: error.localizedDescription)) 🌎🌎")
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
            sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.entered)
        } else if state == .outside && region.notifyOnExit {
            sendGeofenceTrackingEvent(region: region, triggeredTransition: LocationKey.exited)
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
        var data = [String: Any]()
        data[LocationKey.geofenceName] = "\(region.identifier)"
        data[LocationKey.geofenceTransition] = "\(triggeredTransition)"
        data[TealiumKey.event] = triggeredTransition

        if let lastLocation = lastLocation {
            data[LocationKey.deviceLatitude] = "\(lastLocation.coordinate.latitude)"
            data[LocationKey.deviceLongitude] = "\(lastLocation.coordinate.longitude)"
            data[LocationKey.timestamp] = "\(lastLocation.timestamp)"
            data[LocationKey.speed] = "\(lastLocation.speed)"
            data[LocationKey.accuracy] = locationAccuracy
        }

        if triggeredTransition == LocationKey.exited {
            locationDelegate?.didExitGeofence(data)
        } else if triggeredTransition == LocationKey.entered {
            locationDelegate?.didEnterGeofence(data)
        }
    }

    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation` location object
    public var lastLocation: CLLocation? {
        get {
            guard locationServiceEnabled else {
                return nil
            }
            return _lastLocation
        }
        set {
            if let newValue = newValue {
                _lastLocation = newValue
            }
        }
    }

    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofences: `[CLCircularRegion]` Geofences to be added
    public func startMonitoring(_ geofences: [CLCircularRegion]) {
        if geofences.capacity == 0 {
            return
        }

        geofences.forEach {
            startMonitoring(geofence: $0)
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
    /// - parameter geofences: `[CLCircularRegion]` Geofences to be removed
    public func stopMonitoring(_ geofences: [CLCircularRegion]) {
        if geofences.capacity == 0 {
            return
        }

        geofences.forEach {
            stopMonitoring(geofence: $0)
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
    /// - return: `[String]?` Array containing the names of monitored geofences
    public var monitoredGeofences: [String]? {
        guard locationServiceEnabled else {
            return nil
        }
        return locationManager.monitoredRegions.map { $0.identifier }
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]?` Array containing the names of all geofences
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

    /// Logs errors about events occuring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location", message: message, info: nil, logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about events occuring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location", message: message, info: nil, logLevel: .debug, category: .general)
        logger?.log(logRequest)
    }

}
#endif
