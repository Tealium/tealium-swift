//
//  TealiumLocationManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
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

    var geofenceTrackingEnabled: Bool {
        config.geofenceTrackingEnabled && !geofences.isEmpty
    }

    var locationManager: LocationManagerProtocol
    var geofences = [Geofence]()
    weak var locationDelegate: LocationDelegate?
    public var locationAccuracy: String = LocationKey.highAccuracy
    private var _lastLocation: CLLocation?

    @ToAnyObservable<TealiumReplaySubject>(TealiumReplaySubject())
    var onReady: TealiumObservable<Void>

    init(config: TealiumConfig,
         bundle: Bundle = Bundle.main,
         locationDelegate: LocationDelegate? = nil,
         locationManager: LocationManagerProtocol = CLLocationManager()) {
        self.config = config
        self.locationDelegate = locationDelegate
        self.locationManager = locationManager
        self.locationAccuracy = config.useHighAccuracy ? LocationKey.highAccuracy : LocationKey.lowAccuracy

        super.init()

        let provider = GeofenceProvider(config: config, bundle: bundle)
        provider.getGeofencesAsync { [weak self] geofences in
            guard let self = self else { return }
            self.geofences = geofences
            self._onReady.publish()
        }

        self.locationManager.distanceFilter = config.updateDistance
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = CLLocationAccuracy(config.desiredAccuracy)
        self.locationManager.allowsBackgroundLocationUpdates = config.enableBackgroundLocation

        clearMonitoredGeofences()
    }

    /// - Returns: `Bool` Whether or not the user has authorized location tracking/updates
    public var isAuthorized: Bool {
        type(of: locationManager).self.authorizationStatus() == .authorizedAlways ||
            type(of: locationManager).self.authorizationStatus() == .authorizedWhenInUse
    }

    /// - Returns: `Bool` Whether or not the user has allowed "Precise" location tracking/updates
    @available(iOS 14.0, *)
    public var isFullAccuracy: Bool {
        return locationManager.accuracyAuthorization == .fullAccuracy
    }

    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation ` location object
    public var lastLocation: CLLocation? {
        get {
            guard isAuthorized else {
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

    /// Prompts the user to enable permission for location servies
    public func requestAuthorization() {
        let authorizationStatus = type(of: locationManager).self.authorizationStatus()

        if authorizationStatus != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }

        if authorizationStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Prompts the user to enable permission for location servies
    public func requestWhenInUseAuthorization() {
        let authorizationStatus = type(of: locationManager).self.authorizationStatus()

        if authorizationStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    /// Automatically request temporary full accuracy if precise accuracy is disabled.
    ///
    /// - Parameter purposeKey: `String` A key in the `NSLocationTemporaryUsageDescriptionDictionary` dictionary of the app’s `Info.plist` file.
    @available(iOS 14.0, *)
    public func requestTemporaryFullAccuracyAuthorization(purposeKey: String) {
        guard isAuthorized else {
            return
        }
        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { [weak self] error in
            if let self = self,
               let error = error as? CLError {
                if error.code == .denied {
                    self.logError(message: "🌎🌎 Temporary Full Authorization Denied 🌎🌎")
                } else {
                    self.logError(message: "🌎🌎 Error Requesting Temporary Full Authorization: \(error) 🌎🌎")
                }

            }
        }
    }

    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initialization of this class.
    public func startLocationUpdates() {
        onReady.subscribeOnce { [weak self] in
            guard let self = self else {
                return
            }
            guard self.isAuthorized else {
                self.logInfo(message: "🌎🌎 Location Updates Service Not Enabled 🌎🌎")
                return
            }
            guard !self.config.useHighAccuracy,
                  CLLocationManager.significantLocationChangeMonitoringAvailable() else {
                self.locationManager.startUpdatingLocation()
                self.logInfo(message: "🌎🌎 Starting Location Updates With Frequent Monitoring 🌎🌎")
                return
            }
            self.locationManager.startMonitoringSignificantLocationChanges()
            self.logInfo(message: "🌎🌎 Starting Location Updates With Significant Location Changes Only 🌎🌎")
        }
    }

    /// Stops the updating of location data through the location client.
    public func stopLocationUpdates() {
        guard isAuthorized else {
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
            logInfo(message: "🌎🌎 Location updated: \(String(describing: lastLocation.coordinate)) 🌎🌎")
        }
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
            logError(message: "🌎🌎 Location Authorization Denied 🌎🌎")
            locationManager.stopUpdatingLocation()
        } else {
            logError(message: "🌎🌎 An Error Has Occured: \(String(describing: error.localizedDescription)) 🌎🌎")
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

    /// `CLLocationManagerDelegate` method
    /// Calls for the sending of a Tealium tracking calls on geofence enter and exit event. Deprecated in iOS 14
    ///
    /// - parameter manager: `CLLocationManager` instance
    /// - parameter status: `CLAuthorizationStatus` authorization state of the application.
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startLocationUpdates()
    }

    /// `CLLocationManagerDelegate` method
    /// Calls for the sending of a Tealium tracking calls on geofence enter and exit event. Available in iOS 14 only
    ///
    /// - parameter manager: `CLLocationManager` instance
    @available(iOS 14.0, *)
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        startLocationUpdates()
    }

    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occured
    public func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        guard geofenceTrackingEnabled else {
            return
        }

        // Check we are actively monitoring for this geofence and it didn't come from another SDK
        guard isMonitoredByModule(region: region) else {
            return
        }

        var data = [String: Any]()
        data[TealiumDataKey.geofenceName] = "\(region.identifier)"
        data[TealiumDataKey.geofenceTransition] = "\(triggeredTransition)"
        data[TealiumDataKey.event] = triggeredTransition

        if let lastLocation = lastLocation {
            data[TealiumDataKey.deviceLatitude] = "\(lastLocation.coordinate.latitude)"
            data[TealiumDataKey.deviceLongitude] = "\(lastLocation.coordinate.longitude)"
            data[TealiumDataKey.locationTimestamp] = "\(lastLocation.timestamp)"
            data[TealiumDataKey.locationSpeed] = "\(lastLocation.speed)"
            data[TealiumDataKey.locationAccuracy] = locationAccuracy
            data[TealiumDataKey.locationAccuracyExtended] = config.desiredAccuracy.rawValue
        }

        if triggeredTransition == LocationKey.exited {
            locationDelegate?.didExitGeofence(data)
        } else if triggeredTransition == LocationKey.entered {
            locationDelegate?.didEnterGeofence(data)
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
        guard geofenceTrackingEnabled else {
            return
        }
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
        guard isAuthorized else {
            return nil
        }
        return locationManager.monitoredRegions.map { $0.identifier }
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]?` Array containing the names of all geofences
    public var createdGeofences: [String]? {
        guard isAuthorized else {
            return nil
        }
        return geofences.map { $0.name }
    }

    /// Removes all geofences that are currently being monitored from the Location Client
    public func clearMonitoredGeofences() {

        locationManager.monitoredRegions.forEach { region in
            // Check we are actively monitoring for this geofence and it didn't come from another SDK
            guard isMonitoredByModule(region: region) else {
                return
            }

            locationManager.stopMonitoring(for: region)
        }
    }

    /// Checks if a region is currently being monitored
    func isMonitoredByModule(region: CLRegion) -> Bool {
        guard let createdGeofences = createdGeofences else {
            return false
        }
        return createdGeofences.contains(where: { $0 == region.identifier })
    }

    /// Stops location updates, Removes all active geofences from being monitored,
    /// and resets the array of created geofences
    public func disable() {
        stopLocationUpdates()
        clearMonitoredGeofences()
        self.geofences = [Geofence]()
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

extension CLLocationAccuracy {
    init(_ accuracy: LocationAccuracy) {
        switch accuracy {
        case .bestForNavigation:
            self = kCLLocationAccuracyBestForNavigation
        case .best:
            self = kCLLocationAccuracyBest
        case .nearestTenMeters:
            self = kCLLocationAccuracyNearestTenMeters
        case .nearestHundredMeters:
            self = kCLLocationAccuracyHundredMeters
        case .reduced:
            if #available(iOS 14.0, *) {
                self = kCLLocationAccuracyReduced
            } else {
                self = kCLLocationAccuracyHundredMeters
            }
        case .withinOneKilometer:
            self = kCLLocationAccuracyKilometer
        case .withinThreeKilometers:
            self = kCLLocationAccuracyThreeKilometers
        }
    }
}

#endif
