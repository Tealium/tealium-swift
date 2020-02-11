//
//  TealiumHelper.swift
//
//  Created by Christina S on 11/8/19.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation
import TealiumAppData
import TealiumCore
import TealiumCollect
import TealiumConnectivity
import TealiumConsentManager
import TealiumDelegate
import TealiumDeviceData
import TealiumDispatchQueue
import TealiumLifecycle
import TealiumLogger
import TealiumPersistentData
import TealiumVisitorService
import TealiumVolatileData
#if os(iOS)
import TealiumAttribution
import TealiumLocation
import TealiumRemoteCommands
import TealiumTagManagement
#endif

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
        datasource: TealiumConfiguration.dataSourceKey)

    var tealium: Tealium?

    // MARK: Tealium Initilization
    private init() {
        // Optional Config Settings
        if enableLogs { config.logLevel = .verbose }
        config.connectivityRefreshInterval = 5
        config.consentLoggingEnabled = true
        config.initialUserConsentStatus = .consented
        config.shouldUseRemotePublishSettings = false
        config.memoryReportingEnabled = true
        config.visitorServiceRefreshInterval = 0
        config.visitorServiceOverrideProfile = "main"
        config.diskStorageEnabled = true
        config.batterySaverEnabled = true
        // Batching
        config.batchSize = 5
        config.dispatchAfter = 5
        config.dispatchQueueLimit = 200
        config.batchingEnabled = true
        
        #if os(iOS)
        config.searchAdsEnabled = true
        config.shouldAddCookieObserver = false
        config.remoteAPIEnabled = true
        // Location
        config.useHighAccuracy = true
        config.updateDistance = 150.0
        config.geofenceUrl = "https://tags.tiqcdn.com/dle/tealiummobile/location/geofences.json"
        config.shouldRequestPermission = true
        #endif
        
        // External and Visitor Service delegate
        config.addDelegate(self)
        config.addVisitorServiceDelegate(self)

        // Remote command example
        #if os(iOS)
            let remoteCommand = TealiumRemoteCommand(commandId: "example",
                description: "Example Remote Command") { response in
                // use the respose payload from the webview to do something
                print(response.payload())
            }
            config.addRemoteCommand(remoteCommand)
        #endif

        tealium = Tealium(config: config) { response in
            // Optional post init processing
            self.tealium?.volatileData()?.add(data: ["key1": "value1"])
        }

    }

    public func start() {
        _ = TealiumHelper.shared
    }

    class func trackView(title: String, data: [String: Any]?) {
        TealiumHelper.shared.tealium?.track(title: title, data: data, completion: nil)
    }

    class func trackEvent(title: String, data: [String: Any]?) {
        TealiumHelper.shared.tealium?.track(title: title, data: data, completion: nil)
    }

    class func joinTrace(_ traceID: String) {
        TealiumHelper.shared.tealium?.joinTrace(traceId: traceID)
        TealiumHelper.trackEvent(title: "trace_started", data: nil)
    }

    class func leaveTrace() {
        TealiumHelper.shared.tealium?.leaveTrace()
    }
}

// MARK: Visitor Service Module Delegate
extension TealiumHelper: TealiumVisitorServiceDelegate {
    func profileDidUpdate(profile: TealiumVisitorProfile?) {
        guard let profile = profile else {
            return
        }
        if let json = try? JSONEncoder().encode(profile), let string = String(data: json, encoding: .utf8) {
            if enableLogs {
                print(string)
            }
        }
    }
}

// MARK: Tealium Delegate
extension TealiumHelper: TealiumDelegate {

    func tealiumShouldTrack(data: [String: Any]) -> Bool {
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        if enableLogs {
            print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))" : "")")
        }
    }
}

// MARK: Tealium Consent Manager Delegate
extension TealiumHelper: TealiumConsentManagerDelegate {
    func willDropTrackingCall(_ request: TealiumTrackRequest) {
        // ...
    }

    func willQueueTrackingCall(_ request: TealiumTrackRequest) {
        // ...
    }

    func willSendTrackingCall(_ request: TealiumTrackRequest) {
        // ...
    }

    func consentStatusChanged(_ status: TealiumConsentStatus) {
        // ...
    }

    func userConsentedToTracking() {
        // ...
    }

    func userOptedOutOfTracking() {
        // ...
    }

    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {
        // ...
    }


}
