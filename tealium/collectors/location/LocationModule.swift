//
//  LocationModule.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import CoreLocation
import Foundation
#if location
import TealiumCore
#endif

/// Module to add app related data to track calls.
public class LocationModule: Collector {

    public let id: String = ModuleNames.location
    public var config: TealiumConfig
    weak var delegate: ModuleDelegate?
    public var tealiumLocationManager: TealiumLocationManagerProtocol?

    public var data: [String: Any]? {
        var newData = [String: Any]()
        guard let tealiumLocationManager = tealiumLocationManager else {
            return nil
        }
        if let location = tealiumLocationManager.lastLocation,
           location.coordinate.latitude != 0.0 && location.coordinate.longitude != 0.0 {
            newData = [LocationKey.deviceLatitude: "\(location.coordinate.latitude)",
                       LocationKey.deviceLongitude: "\(location.coordinate.longitude)",
                       LocationKey.accuracy: tealiumLocationManager.locationAccuracy,
                       LocationKey.accuracyExtended: config.desiredAccuracy.rawValue]
        }
        return newData
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter diskStorage: `TealiumDiskStorageProtocol` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.config = context.config
        self.delegate = delegate

        if Thread.isMainThread {
            tealiumLocationManager = TealiumLocationManager(config: self.config, locationDelegate: self)
        } else {
            TealiumQueues.mainQueue.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.tealiumLocationManager = TealiumLocationManager(config: self.config, locationDelegate: self)
            }
        }

    }

    /// Removes all geofences that are currently being monitored from the Location Client
    public func clearMonitoredGeofences() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.clearMonitoredGeofences()
        }
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - return: `[String]?` Array containing the names of all geofences
    public var createdGeofences: [String]? {
        var created: [String]?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            created = self.tealiumLocationManager?.createdGeofences
        }
        return created
    }

    /// Disables the module and deletes all associated data
    func disable() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.disable()
        }
    }

    /// - Returns: `Bool` Whether or not the user has authorized location tracking/updates
    var isAuthorized: Bool? {
        var authorized: Bool?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            authorized = self.tealiumLocationManager?.isAuthorized
        }
        return authorized
    }

    /// - Returns: `Bool` Whether or not the user has allowed "Precise" location tracking/updates
    @available(iOS 14.0, *)
    var isFullAccuracy: Bool? {
        var fullAccuracy: Bool?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            fullAccuracy = self.tealiumLocationManager?.isFullAccuracy
        }
        return fullAccuracy
    }

    /// Gets the user's last known location
    ///
    /// - returns: `CLLocation?` location object
    public var lastLocation: CLLocation? {
        var latest: CLLocation?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            latest = self.tealiumLocationManager?.lastLocation
        }
        return latest
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - return: `[String]?` Array containing the names of monitored geofences
    public var monitoredGeofences: [String]? {
        var monitored: [String]?
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            monitored = self.tealiumLocationManager?.monitoredGeofences
        }
        return monitored
    }

    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occured
    public func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.sendGeofenceTrackingEvent(region: region, triggeredTransition: triggeredTransition)
        }
    }

    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initisalizatuion of this class.
    public func startLocationUpdates() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.startLocationUpdates()
        }
    }

    /// Stops the updating of location data through the location client.
    public func stopLocationUpdates() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.stopLocationUpdates()
        }
    }

    /// Adds geofences to the Location Client to be monitored
    ///
    /// - parameter geofences: `[CLCircularRegion]` Geofences to be added
    public func startMonitoring(geofences: [CLCircularRegion]) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.startMonitoring(geofences)
        }
    }

    /// Removes geofences from being monitored by the Location Client
    ///
    /// - parameter geofences: `[CLCircularRegion]` Geofences to be removed
    public func stopMonitoring(geofences: [CLCircularRegion]) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.stopMonitoring(geofences)
        }
    }

    /// Prompts the user to enable permission for location servies
    public func requestAuthorization() {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.requestAuthorization()
        }
    }

    /// Automatically request temporary full accuracy if precise accuracy is disabled.
    ///
    /// - Parameter purposeKey: `String` A key in the `NSLocationTemporaryUsageDescriptionDictionary` dictionary of the app’s `Info.plist` file.
    @available(iOS 14, *)
    public func requestTemporaryFullAccuracyAuthorization(purposeKey: String) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.requestTemporaryFullAccuracyAuthorization(purposeKey: purposeKey)
        }
    }

}

extension LocationModule: LocationDelegate {

    func didEnterGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data)
        delegate?.requestTrack(trackRequest)
    }

    func didExitGeofence(_ data: [String: Any]) {
        let trackRequest = TealiumTrackRequest(data: data)
        delegate?.requestTrack(trackRequest)
    }
}
#endif
