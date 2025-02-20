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

public struct Geofence: Codable, Equatable {
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

class GeofenceProvider: ItemsProvider<Geofence> {
    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    private static func url(from config: TealiumConfig) -> String {
        return "\(TealiumValue.tealiumDleBaseURL)\(config.account)/\(config.profile)/\(LocationKey.fileName).json"
    }
    private static func itemLocation(from config: TealiumConfig) -> ItemsFileLocation {
        switch config.initializeGeofenceDataFrom {
        case .tealium:
            return .remote(self.url(from: config))
        case .localFile(let string):
            return .local(string)
        case .customUrl(let string):
            return .remote(string)
        default:
            return .none
        }
    }
    init(config: TealiumConfig,
         bundle: Bundle,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         diskStorage: TealiumDiskStorageProtocol) {
        super.init(id: "geofences",
                   location: Self.itemLocation(from: config),
                   bundle: bundle,
                   urlSession: urlSession,
                   diskStorage: diskStorage,
                   logger: config.logger)
    }

    override func reportLoadedItems(items: [Geofence]) {
        super.reportLoadedItems(items: filter(geofences: items))
    }

    private func filter(geofences: [Geofence]) -> [Geofence] {
        return geofences.filter {
            $0.name.count > 0
                && $0.latitude >= -90.0 && $0.latitude <= 90.0
                && $0.longitude >= -180.0 && $0.longitude <= 180.0
                && $0.radius > 0
        }
    }
}

#else
#endif
