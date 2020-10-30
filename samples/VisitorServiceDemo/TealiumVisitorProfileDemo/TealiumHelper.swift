//
//  TealiumHelper.swift
//  TealiumVisitorProfileDemo
//
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
    static let datasource = "test123" // UDH data source key
}

enum TealiumSampleAudiences: String {
    case cartabandoners = "tealiummobile_demo_107", // Cart Abandoners
         travelers = "tealiummobile_demo_108", // Frequent Travelers
         highscorers = "tealiummobile_demo_109" // High Scoring Gamers
}

// Note: update this to false if you want to disable logging
let enableLogs = true

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
                               profile: TealiumConfiguration.profile,
                               environment: TealiumConfiguration.environment,
                               dataSource: TealiumConfiguration.datasource)

    var tealium: Tealium?

    private init() {
        if enableLogs { config.logLevel = .debug }
        config.shouldUseRemotePublishSettings = false // Note: change to true to use TiQ for publish settings
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self

        // To enable batching:
        // config.batchingEnabled = true
        // config.batchSize = 5

        #if os(iOS)
        // Add dispatchers
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.Collect]
        #else
        config.dispatchers = [Dispatchers.Collect]
        #endif

        // Add collectors
        config.collectors = [Collectors.Lifecycle, Collectors.VisitorService]

        // To enable location:
        #if os(iOS)
        // config.collectors?.append(Collectors.Location)
        // config.useHighAccuracy = true
        // config.updateDistance = 150.0
        // config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        #endif

        tealium = Tealium(config: config) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.tealium?.track(TealiumEvent("tealium_initialized"))
        }

    }

    public func start() {
        _ = TealiumHelper.shared
    }

    class func trackView(title: String, dataLayer: [String: Any]? = nil) {
        let tealiumView = TealiumView(title, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(tealiumView)
    }

    class func trackScreen(_ view: UIViewController, name: String) {
        TealiumHelper.trackView(title: "screen_view",
                                dataLayer: ["screen_name": name,
                                            "screen_class": "\(view.classForCoder)"])
    }

    class func trackEvent(name: String, dataLayer: [String: Any]? = nil) {
        let tealiumEvent = TealiumEvent(name, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(tealiumEvent)
    }

    class func joinTrace(id: String) {
        TealiumHelper.shared.tealium?.joinTrace(id: id)
        TealiumHelper.trackEvent(name: "trace", dataLayer: ["tealium_trace_id": id])
    }

    class func leaveTrace() {
        TealiumHelper.shared.tealium?.leaveTrace()
    }

    class func killTrace(traceId: String) {
        TealiumHelper.trackEvent(name: "kill_trace",
                                 dataLayer: ["event": "kill_visitor_session",
                                             "cp.trace_id": traceId])
    }

    class func updateExperience(basedOn audience: TealiumSampleAudiences,
                                _ experienceUpdate: @escaping () -> Void) {
        // most recently saved audiences
        guard let profile = TealiumHelper.shared.tealium?.visitorService?.cachedProfile, profile.audiences?[audience.rawValue] != nil else {
            return
        }
        experienceUpdate()
    }

}

extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile),
           let string = String(data: json, encoding: .utf8) {
            if enableLogs {
                print("Current visitor profile: \(string)")
            }
        }
    }
}
