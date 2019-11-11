//
//  TealiumHelper.swift
//
//  Created by Christina S on 11/8/19.
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
        if enableLogs { config.setLogLevel(.verbose) }
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking",
                                                    "tagmanagement"])
        config.setModulesList(list)
        config.setMemoryReportingEnabled(true)
        config.setDiskStorageEnabled(isEnabled: true)
        config.addVisitorServiceDelegate(self)
        config.setInitialUserConsentStatus(.consented)
        config.setConsentLoggingEnabled(true)
        config.addDelegate(self)
        // To enable batching:
        // config.setBatchSize(5)
        // config.setIsEventBatchingEnabled(true)
        
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
            print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))":"")")
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
