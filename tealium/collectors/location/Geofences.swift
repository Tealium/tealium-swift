//
//  Geofences.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium. All rights reserved.
//

#if os(iOS)
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

public struct GeofenceData: Codable {

    var geofences: [Geofence]?
    var logger: TealiumLoggerProtocol?

    enum CodingKeys: String, CodingKey {
        case geofences
    }

    init?(file: String, bundle: Bundle, logger: TealiumLoggerProtocol? = nil) {

        guard let path = bundle.path(forResource: file.replacingOccurrences(of: ".json", with: ""),
                                     ofType: "json") else {
            logError(message: LocationErrors.noFile)
            return nil
        }
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            logError(message: LocationErrors.couldNotRetrieve)
            return nil
        }
        guard let geofenceData = try? Tealium.jsonDecoder.decode([Geofence].self, from: jsonData) else {
            logError(message: LocationErrors.couldNotDecode)
            return nil
        }
        geofences = filter(geofences: geofenceData)
        logInfo(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎")
    }

    init?(url: String, logger: TealiumLoggerProtocol? = nil) {
        guard !url.isEmpty else {
            logError(message: LocationErrors.noUrl)
            return
        }
        guard let geofenceUrl = URL(string: url) else {
            logError(message: LocationErrors.invalidUrl)
            return
        }
        do {
            let jsonString = try String(contentsOf: geofenceUrl)
            guard let data = jsonString.data(using: .utf8),
                  let geofenceData = try? Tealium.jsonDecoder.decode([Geofence].self, from: data) else {
                return
            }
            geofences = filter(geofences: geofenceData)
            logInfo(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎")
        } catch let error {
            logError(message: "Error \(error.localizedDescription)")
        }
    }

    init?(json: String, logger: TealiumLoggerProtocol? = nil) {
        guard !json.isEmpty else {
            logError(message: LocationErrors.noJson)
            return
        }
        guard let data = json.data(using: .utf8),
              let geofenceData = try? Tealium.jsonDecoder.decode([Geofence].self, from: data) else {
            logError(message: LocationErrors.couldNotDecode)
            return
        }
        geofences = filter(geofences: geofenceData)
        logInfo(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎")
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
