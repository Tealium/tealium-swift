//
//  TealiumHelper.swift
//  TealiumMediaExample
//

import Foundation
import TealiumSwift

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
    static let dataSourceKey = "abc123"
}

let enableLogs = true // change to false to disable logging

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
        profile: TealiumConfiguration.profile,
        environment: TealiumConfiguration.environment,
        dataSource: TealiumConfiguration.dataSourceKey)

    var tealium: Tealium?
    
    // MARK: Tealium Initilization
    private init() {
        // Optional Config Settings
        if enableLogs { config.logLevel = .info }
        config.shouldUseRemotePublishSettings = false
        config.memoryReportingEnabled = true
        config.enableBackgroundMediaTracking = true
        config.backgroundMediaAutoEndSessionTime = 30.0
        config.collectors = [Collectors.AppData,
                             Collectors.Device,
                             Collectors.Connectivity,
                             Collectors.Lifecycle,
                             Collectors.Media]
        config.dispatchers = [Dispatchers.Collect]

        tealium = Tealium(config: config)
    }

    public func start() {
        _ = TealiumHelper.shared
    }
    
    class func mediaSession(from media: MediaContent) -> MediaSession? {
        guard let mediaModule = TealiumHelper.shared.tealium?.media else {
            return nil
        }
        return mediaModule.createSession(from: media)
    }

    class func trackView(title: String, data: [String: Any]?) {
        let viewDispatch = TealiumView(title, dataLayer: data)
        TealiumHelper.shared.tealium?.track(viewDispatch)
    }

    class func trackEvent(title: String, data: [String: Any]?) {
        let eventDispatch = TealiumEvent(title, dataLayer: data)
        TealiumHelper.shared.tealium?.track(eventDispatch)
    }

    class func joinTrace(_ traceId: String) {
        TealiumHelper.shared.tealium?.joinTrace(id: traceId)
        TealiumHelper.trackEvent(title: "trace_started", data: nil)
    }

    class func killTrace(_ traceId: String) {
        TealiumHelper.trackEvent(title: "kill_trace",
                                 data: ["event": "kill_visitor_session",
                                             "cp.trace_id": traceId])
    }
}
