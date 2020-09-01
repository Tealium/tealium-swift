//
//  TealiumHelper.swift
//
//  Created by Christina S on 7/6/20.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

enum TealiumConfiguration {
    static let account = "tealiummobile"
    static let profile = "demo"
    static let environment = "dev"
    static let dataSourceKey = "abc123"
}

let enableLogs = true

public enum WebViewExampleType: Equatable {
    case noUtag // example webview without utag
    case withUtag // example webview with mobile.html/utag.js
}

class TealiumHelper {

    static let shared = TealiumHelper()

    let config = TealiumConfig(account: TealiumConfiguration.account,
                               profile: TealiumConfiguration.profile,
                               environment: TealiumConfiguration.environment,
                               dataSource: TealiumConfiguration.dataSourceKey)

    var tealium: Tealium?
    
    // set this to change the example that loads - JSInterfaceExample
    public var exampleType: WebViewExampleType = .withUtag

    // MARK: Tealium Initilization
    private init() {
        // Optional Config Settings
        if enableLogs { config.logLevel = .info }

        config.shouldUseRemotePublishSettings = false
        config.memoryReportingEnabled = true
        config.diskStorageEnabled = true
        config.visitorServiceDelegate = self
        config.consentLoggingEnabled = true
        config.consentPolicy = .ccpa
        
        #if os(iOS)
        // Add dispatchers
        config.dispatchers = [Dispatchers.TagManagement, Dispatchers.RemoteCommands]
        #else
        config.dispatchers = [Dispatchers.Collect]
        #endif
        
        // Add collectors
        #if os(iOS)
        config.collectors = [Collectors.Attribution, Collectors.VisitorService, Collectors.Location]
        
        // To enable batching:
        // config.batchSize = 5
        // config.batchingEnabled = true
        
        // Location - Geofence Monitoring
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        config.useHighAccuracy = true
        config.updateDistance = 200.0
        
        // Remote Commands
        let remoteCommand = RemoteCommand(commandId: "hello", description: "world") { response in
            guard let payload = response.payload else {
                return
            }
            // Do something w/remote command payload
            if enableLogs {
                print(payload)
            }
        }
        config.addRemoteCommand(remoteCommand)
        #endif
        
        tealium = Tealium(config: config) { response in
            // Optional post init processing
            self.tealium?.dataLayer.add(data: ["somekey": "someval"], expiry: .afterCustom((.months, 1)))
            self.tealium?.dataLayer.add(key: "someotherkey", value: "someotherval", expiry: .forever)
            #if os(iOS)
            // Location
            self.tealium?.location?.requestAuthorization()
            #endif
        }

    }

    public func start() {
        _ = TealiumHelper.shared
    }

    class func trackView(title: String, dataLayer: [String: Any]?) {
        let dispatch = TealiumView(title, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(dispatch)
    }

    class func trackEvent(title: String, dataLayer: [String: Any]?) {
        let dispatch = TealiumEvent(title, dataLayer: dataLayer)
        TealiumHelper.shared.tealium?.track(dispatch)
    }
    
    class func joinTrace(_ traceID: String) {
        TealiumHelper.shared.tealium?.joinTrace(id: traceID)
        TealiumHelper.trackEvent(title: "trace_started", dataLayer: nil)
    }

    class func leaveTrace() {
        TealiumHelper.shared.tealium?.leaveTrace()
    }
}

// MARK: Visitor Service Module Delegate
extension TealiumHelper: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        if let json = try? JSONEncoder().encode(visitorProfile),
            let string = String(data: json, encoding: .utf8) {
            if enableLogs {
                print(string)
            }
        }
    }
}
