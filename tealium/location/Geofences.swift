//
//  Geofences.swift
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

public typealias Geofences = [Geofence]

public extension Geofences {
    var regions: [CLCircularRegion] {
        return self.map {
            $0.region
        }
    }
}

public struct GeofenceData: Codable {

    var geofences: Geofences?

    init?(file: String, bundle: Bundle) {
        let logger = TealiumLogger(loggerId: TealiumLocationKey.name, logLevel: .errors)
        guard let path = bundle.path(forResource: file.replacingOccurrences(of: ".json", with: ""),
            ofType: "json") else {
            logger.log(message: TealiumLocationErrors.noFile.rawValue, logLevel: .errors)
            return nil
        }
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            logger.log(message: TealiumLocationErrors.couldNotRetrieve.rawValue, logLevel: .errors)
            return nil
        }
        guard let geofenceData = try? JSONDecoder().decode(Geofences.self, from: jsonData) else {
            logger.log(message: TealiumLocationErrors.couldNotDecode.rawValue, logLevel: .errors)
            return nil
        }
        geofences = filter(geofences: geofenceData)
        logger.log(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎", logLevel: .verbose)
    }

    init?(url: String) {
        let logger = TealiumLogger(loggerId: TealiumLocationKey.name, logLevel: .errors)
        guard !url.isEmpty else {
            logger.log(message: TealiumLocationErrors.noUrl.rawValue, logLevel: .errors)
            return
        }
        guard let geofenceUrl = URL(string: url) else {
            logger.log(message: TealiumLocationErrors.invalidUrl.rawValue, logLevel: .errors)
            return
        }
        do {
            let jsonString = try String(contentsOf: geofenceUrl)
            guard let data = jsonString.data(using: .utf8),
                let geofenceData = try? JSONDecoder().decode(Geofences.self, from: data) else {
                    return
            }
            geofences = filter(geofences: geofenceData)
            logger.log(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎", logLevel: .verbose)
        } catch let error {
            logger.log(message: "Error \(error.localizedDescription)", logLevel: .errors)
        }
    }

    init?(json: String) {
        let logger = TealiumLogger(loggerId: TealiumLocationKey.name, logLevel: .errors)
        guard !json.isEmpty else {
            logger.log(message: TealiumLocationErrors.noJson.rawValue, logLevel: .errors)
            return
        }
        guard let data = json.data(using: .utf8),
            let geofenceData = try? JSONDecoder().decode(Geofences.self, from: data) else {
                logger.log(message: TealiumLocationErrors.couldNotDecode.rawValue, logLevel: .errors)
                return
        }
        geofences = filter(geofences: geofenceData)
        logger.log(message: "🌎🌎 \(String(describing: geofences?.count)) Geofences Created 🌎🌎", logLevel: .verbose)
    }

    func filter(geofences: Geofences) -> Geofences {
        return geofences.filter {
            $0.name.count > 0
                && $0.latitude >= -90.0 && $0.latitude <= 90.0
                && $0.longitude >= -180.0 && $0.longitude <= 180.0
                && $0.radius > 0
        }
    }
}

