//
//  Geofences.swift
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

public struct Geofence: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Int
    let triggerOnEnter: Bool
    let triggerOnExit: Bool

    public enum CodingKeys: String, CodingKey {
        case name
        case latitude
        case longitude
        case radius
        case triggerOnEnter = "trigger_on_enter"
        case triggerOnExit = "trigger_on_exit"
    }

    var region: CLCircularRegion {
        let region = CLCircularRegion(center: CLLocationCoordinate2DMake(self.latitude, self.longitude), radius: CLLocationDistance(radius), identifier: self.name)
        region.notifyOnEntry = triggerOnEnter
        region.notifyOnExit = triggerOnExit
        return region
    }

}

public extension Array where Element == Geofence {
    var regions: [CLCircularRegion] {
        return self.map {
            $0.region
        }
    }
}

class GeofenceProvider {
    private var logger: TealiumLoggerProtocol? {
        config.logger
    }
    private let bundle: Bundle
    private let config: TealiumConfig
    init(config: TealiumConfig, bundle: Bundle) {
        self.config = config
        self.bundle = bundle
    }

    func getGeofencesAsync(completion: @escaping ([Geofence]) -> Void) {
        guard config.initializeGeofenceDataFrom != nil else {
            completion([])
            return
        }
        TealiumQueues.backgroundSerialQueue.async {
            let geofences = self.getGeofences()
            TealiumQueues.mainQueue.async {
                completion(geofences)
            }
        }
    }

    private func getGeofences() -> [Geofence] {
        do {
            let geofenceData = try fetchGeofences()
            let geofences = filter(geofences: geofenceData)
            logInfo(message: "🌎🌎 \(String(describing: geofences.count)) Geofences Created 🌎🌎")
            return geofences
        } catch {
            logError(message: error.localizedDescription)
            return []
        }
    }

    private func fetchGeofences() throws -> [Geofence] {
        guard let locationConfig = config.initializeGeofenceDataFrom else {
            return []
        }
        switch locationConfig {
        case .localFile(let file):
            return try JSONLoader.fromFile(file, bundle: bundle)
        case .customUrl(let url):
            return try JSONLoader.fromURL(url: url)
        default:
            return try JSONLoader.fromURL(url: self.url(from: config))
        }
    }

    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    private func url(from config: TealiumConfig) -> String {
        return "\(TealiumValue.tealiumDleBaseURL)\(config.account)/\(config.profile)/\(LocationKey.fileName).json"
    }

    func filter(geofences: [Geofence]) -> [Geofence] {
        return geofences.filter {
            $0.name.count > 0
                && $0.latitude >= -90.0 && $0.latitude <= 90.0
                && $0.longitude >= -180.0 && $0.longitude <= 180.0
                && $0.radius > 0
        }
    }

    /// Logs verbose information about events occuring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location",
                                           message: message, info: nil,
                                           logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about events occuring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location",
                                           message: message, info: nil,
                                           logLevel: .debug, category: .general)
        logger?.log(logRequest)
    }

}
#else
#endif
