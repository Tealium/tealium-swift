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
            newData = [TealiumDataKey.deviceLatitude: "\(location.coordinate.latitude)",
                       TealiumDataKey.deviceLongitude: "\(location.coordinate.longitude)",
                       TealiumDataKey.locationAccuracy: tealiumLocationManager.locationAccuracy,
                       TealiumDataKey.locationAccuracyExtended: config.desiredAccuracy.rawValue]
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

        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            let storage = diskStorage ?? TealiumDiskStorage(config: config,
                                                            forModule: ModuleNames.location.lowercased(),
                                                            isCritical: false)
            self.tealiumLocationManager = TealiumLocationManager(config: self.config,
                                                                 diskStorage: storage,
                                                                 locationDelegate: self)
        }
    }

    /// Removes all geofences that are currently being monitored from the Location Client
    public func clearMonitoredGeofences() {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.clearMonitoredGeofences()
        }
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - Warning: Deprecated
    /// Doesn't work out of main thread. Use getCreatedGeofences(completion:) instead.
    ///
    /// - return: `[String]?` Array containing the names of all geofences
    @available(*, deprecated, message: "Doesn't work out of main thread. Use getCreatedGeofences(completion:) instead.")
    public var createdGeofences: [String]? {
        var created: [String]?
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            created = self.tealiumLocationManager?.createdGeofences
        }
        return created
    }

    /// Returns the names of all the created geofences (those currently being monitored and those that are not)
    ///
    /// - parameter completion: Completion block called with the created geofences
    public func getCreatedGeofences(completion: @escaping ([String]?) -> Void) {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            completion(self?.tealiumLocationManager?.createdGeofences)
        }
    }

    /// Disables the module and deletes all associated data
    func disable() {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.disable()
        }
    }

    /// - Returns: `Bool` Whether or not the user has authorized location tracking/updates
    var isAuthorized: Bool? {
        var authorized: Bool?
        TealiumQueues.secureMainThreadExecution { [weak self] in
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
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            fullAccuracy = self.tealiumLocationManager?.isFullAccuracy
        }
        return fullAccuracy
    }

    /// Gets the user's last known location
    ///
    /// - Warning: Deprecated
    /// Doesn't work out of main thread. Use getLatsLocation(completion:) instead.
    ///
    /// - returns: `CLLocation?` location object
    @available(*, deprecated, message: "Doesn't work out of main thread. Use getLatsLocation(completion:) instead.")
    public var lastLocation: CLLocation? {
        var latest: CLLocation?
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            latest = self.tealiumLocationManager?.lastLocation
        }
        return latest
    }

    /// Gets the user's last known location
    ///
    /// - parameter completion: Completion block called with the last known location
    public func getLastLocation(completion: @escaping (CLLocation?) -> Void) {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            completion(self?.tealiumLocationManager?.lastLocation)
        }
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - Warning: Deprecated
    /// Doesn't work out of main thread. Use getMonitoredGeofences(completion:) instead.
    ///
    /// - return: `[String]?` Array containing the names of monitored geofences
    @available(*, deprecated, message: "Doesn't work out of main thread. Use getMonitoredGeofences(completion:) instead.")
    public var monitoredGeofences: [String]? {
        var monitored: [String]?
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            monitored = self.tealiumLocationManager?.monitoredGeofences
        }
        return monitored
    }

    /// Returns the names of all the geofences that are currently being monitored
    ///
    /// - parameter completion: Completion block called with the currently monitored geofences
    public func getMonitoredGeofences(completion: @escaping ([String]?) -> Void) {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            completion(self?.tealiumLocationManager?.monitoredGeofences)
        }
    }

    /// Sends a Tealium tracking event, appending geofence data to the track.
    ///
    /// - parameter region: `CLRegion` that was entered
    /// - parameter triggeredTransition: `String` Type of transition that occurred
    public func sendGeofenceTrackingEvent(region: CLRegion, triggeredTransition: String) {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.sendGeofenceTrackingEvent(region: region, triggeredTransition: triggeredTransition)
        }
    }

    /// Enables regular updates of location data through the location client
    /// Update frequency is dependant on config.useHighAccuracy, a parameter passed on initisalization of this class.
    public func startLocationUpdates() {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.startLocationUpdates()
        }
    }

    /// Stops the updating of location data through the location client.
    public func stopLocationUpdates() {
        TealiumQueues.secureMainThreadExecution { [weak self] in
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
        TealiumQueues.secureMainThreadExecution { [weak self] in
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
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            self.tealiumLocationManager?.stopMonitoring(geofences)
        }
    }

    /// Prompts the user to enable permission for location servies
    public func requestAuthorization() {
        TealiumQueues.secureMainThreadExecution { [weak self] in
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
        TealiumQueues.secureMainThreadExecution { [weak self] in
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
