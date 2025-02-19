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

struct GeofenceFile: Codable, EtagResource {
    let etag: String?
    let geofences: [Geofence]
}
protocol GeofenceProviderDelegate: AnyObject {
    func didLoadGeofences(_ geofences: [Geofence])
}

class GeofenceProvider {
    private var logger: TealiumLoggerProtocol? {
        config.logger
    }
    private let bundle: Bundle
    private let config: TealiumConfig
    private let resourceRefresher: ResourceRefresher<GeofenceFile>?
    weak private var delegate: GeofenceProviderDelegate?
    init(config: TealiumConfig,
         bundle: Bundle,
         urlSession: URLSessionProtocol = URLSession(configuration: .ephemeral),
         diskStorage: TealiumDiskStorageProtocol) {

        func createRefresher(urlString: String?) -> ResourceRefresher<GeofenceFile>? {
            guard let urlString,
                !urlString.isEmpty,
                  let geofenceUrl = URL(string: urlString) else {
                return nil
            }
            let resourceRetriever = ResourceRetriever<GeofenceFile>(urlSession: urlSession) { data, etag in
                guard let geofences = try? JSONDecoder().decode([Geofence].self, from: data) else {
                    return nil
                }
                return GeofenceFile(etag: etag, geofences: geofences)
            }
            let parameters = RefreshParameters<GeofenceFile>(id: "geofences",
                                                             url: geofenceUrl,
                                                             fileName: nil,
                                                             refreshInterval: Double.infinity,
                                                             errorCooldownBaseInterval: Double.infinity)
            let refresher = ResourceRefresher(resourceRetriever: resourceRetriever,
                                              diskStorage: diskStorage,
                                              refreshParameters: parameters)
            return refresher
        }

        self.config = config
        self.bundle = bundle
        switch config.initializeGeofenceDataFrom {
        case .tealium:
            self.resourceRefresher = createRefresher(urlString: Self.url(from: config))
        case .customUrl(let string):
            self.resourceRefresher = createRefresher(urlString: string)
        default:
            self.resourceRefresher = nil
        }
    }

    func loadGeofences(delegate: GeofenceProviderDelegate) {
        self.delegate = delegate
        if let resourceRefresher {
            resourceRefresher.delegate = self
            resourceRefresher.requestRefresh()
        } else if case let .localFile(file) = config.initializeGeofenceDataFrom {
            loadLocalGeofences(file: file)
        }
    }

    private func loadLocalGeofences(file: String) {
        do {
            let geofences: [Geofence] = try JSONLoader.fromFile(file, bundle: bundle, logger: logger)
            reportLoadedGeofences(geofences: geofences)
        } catch {
            reportFailedToLoad(error: error)
        }
    }

    /// Builds a URL from a Tealium config pointing to a hosted JSON file on the Tealium DLE
    private static func url(from config: TealiumConfig) -> String {
        return "\(TealiumValue.tealiumDleBaseURL)\(config.account)/\(config.profile)/\(LocationKey.fileName).json"
    }

    private func filter(geofences: [Geofence]) -> [Geofence] {
        return geofences.filter {
            $0.name.count > 0
                && $0.latitude >= -90.0 && $0.latitude <= 90.0
                && $0.longitude >= -180.0 && $0.longitude <= 180.0
                && $0.radius > 0
        }
    }

    /// Logs verbose information about events occurring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    private func logError(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location",
                                           message: message, info: nil,
                                           logLevel: .error, category: .general)
        logger?.log(logRequest)
    }

    /// Logs verbose information about events occurring in the `TealiumLocation` module
    /// - Parameter message: `String` message to log to the console
    private func logInfo(message: String) {
        let logRequest = TealiumLogRequest(title: "Tealium Location",
                                           message: message, info: nil,
                                           logLevel: .debug, category: .general)
        logger?.log(logRequest)
    }

    private func reportFailedToLoad(error: Error) {
        logError(message: "Failed to load local geofences with error:\n" + error.localizedDescription)
        delegate?.didLoadGeofences([])
    }

    private func reportLoadedGeofences(geofences: [Geofence]) {
        logInfo(message: "🌎🌎 \(String(describing: geofences.count)) Geofences Created 🌎🌎")
        delegate?.didLoadGeofences(filter(geofences: geofences))
    }

}

extension GeofenceProvider: ResourceRefresherDelegate {
    typealias Resource = GeofenceFile
    func resourceRefresher(_ refresher: ResourceRefresher<GeofenceFile>, didLoad resource: GeofenceFile) {
        reportLoadedGeofences(geofences: resource.geofences)
    }

    func resourceRefresher(_ refresher: ResourceRefresher<GeofenceFile>, didFailToLoadResource error: TealiumResourceRetrieverError) {
        if case .non200Response(let code) = error, code != 304 {
            return
        }
        if refresher.readResource() == nil {
            reportFailedToLoad(error: error)
        }
    }
}
#else
#endif
