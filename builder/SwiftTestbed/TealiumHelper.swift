//
//  TealiumHelper.swift
//  SwiftTestbed
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import Tealium

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: TealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
class TealiumHelper: NSObject {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = true
    var traceId = "04136"

    override private init () {

    }

    func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "test12",
                                   optionalData: nil)

        // OPTIONALLY set log level
        config.setMaxQueueSize(20)
        config.setLegacyDispatchMethod(false)
        config.setConnectivityRefreshInterval(interval: 5)
        config.setLogLevel(logLevel: .verbose)
        config.setConsentLoggingEnabled(true)
        config.setSearchAdsEnabled(true)
        config.setInitialUserConsentStatus(.consented)

        // OPTIONALLY add an external delegate
        config.addDelegate(self)

        #if AUTOTRACKING
        print("*** TealiumHelper: Autotracking enabled.")
        #else
        // OPTIONALLY disable a particular module by name
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking", "collect"])
        config.setModulesList(list)
        print("*** TealiumHelper: Autotracking disabled.")
        #endif
        #if os(iOS)

        let remoteCommand = TealiumRemoteCommand(commandId: "hello",
                                                 description: "test") { response in
                                                    if TealiumHelper.shared.enableHelperLogs {
                                                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
                                                    }
                                                    let dict = ["hello":"from helper"]
                                                    // set some JSON response data to be passed back to the webview
                                                    let myJson = try? JSONSerialization.data(withJSONObject: dict, options: [])
                                                    response.data = myJson
        }
        config.addRemoteCommand(remoteCommand)
        #endif

        // REQUIRED Initialization
        tealium = Tealium(config: config) { response in
                            // Optional processing post init.
                            // Optionally, join a trace. Trace ID must be generated server-side in UDH.
                            self.tealium?.joinTrace(traceId: self.traceId)
                            self.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
                            self.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])
                            // OPTIONALLY implement Remote Commands
                            self.tealium?.consentManager()?.addConsentDelegate(self)
                            self.tealium?.consentManager()?.setUserConsentStatus( .consented)
        }
    }

    func track(title: String, data: [String: Any]?) {
        tealium?.track(title: title,
                       data: data,
                       completion: { (success, info, error) in
                        // Optional post processing
                        if self.enableHelperLogs == false {
                            return
                        }
                        print("*** TealiumHelper: track completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")
        })
    }

    func trackView(title: String, data: [String: Any]?) {
        tealium?.track(title: title,
                       data: data,
                       completion: { (success, info, error) in
                        // Optional post processing
                        if self.enableHelperLogs == false {
                            return
                        }
                        // Alternatively, monitoring track completions can be done here vs. using the delegate module's callbacks.
                        print("*** TealiumHelper: view completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")
        })

    }

    func crash() {
        NSException.raise(NSExceptionName(rawValue: "Exception"), format: "This is a test exception", arguments: getVaList(["nil"]))
    }
}

extension TealiumHelper: TealiumDelegate {

    func tealiumShouldTrack(data: [String: Any]) -> Bool {
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        if enableHelperLogs == false {
            return
        }
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))":"")")
    }
}

// MARK: Consent Delegate
extension TealiumHelper: TealiumConsentManagerDelegate {

    func willDropTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call DROPPED ******")
        print(request.data)
    }
    
    func willQueueTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call Queued ******")
        print(request.data)
    }
    
    func willSendTrackingCall(_ request: TealiumTrackRequest) {
        print("**** Tracking call Sent - 1st Helper ******")
        print(request.data)
    }

    func consentStatusChanged(_ status: TealiumConsentStatus) {
        print("Consent Status Changed to: \(status)")
    }
    
    func userConsentedToTracking() {
        print("User consented to tracking")
    }
    
    func userOptedOutOfTracking() {
        print("User opted out of tracking")
    }
    
    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {
        print("User changed consent categories: \(categories)")
    }
}
