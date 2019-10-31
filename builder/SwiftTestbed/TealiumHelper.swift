//
//  TealiumHelper.swift
//  SwiftTestbed
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import TealiumCollect
import TealiumConnectivity
import TealiumAttribution
import TealiumConsentManager
import TealiumDispatchQueue
import TealiumDelegate
import TealiumDeviceData
import TealiumRemoteCommands
import TealiumTagManagement
import TealiumPersistentData
import TealiumVolatileData
import TealiumVisitorService

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: TealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
class TealiumHelper: NSObject {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = false
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
        config.setConnectivityRefreshInterval(5)
        config.setLogLevel(.verbose)
        config.setConsentLoggingEnabled(true)
        config.setSearchAdsEnabled(true)
        config.setInitialUserConsentStatus(.consented)
        config.setBatchSize(5)
        config.setDispatchAfter(numberOfEvents: 5)
        config.setMaxQueueSize(200)
        config.optionalData["enable_visitor_profile"] = true
        config.setIsEventBatchingEnabled(true)
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        config.setMemoryReportingEnabled(true)

        #if AUTOTRACKING
//        print("*** TealiumHelper: Autotracking enabled.")
        #else
        // OPTIONALLY disable a particular module by name
        
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking",])
        config.setModulesList(list)
        config.setDiskStorageEnabled(isEnabled: true)
        config.addVisitorServiceDelegate(self)
        #endif
        #if os(iOS)
        
        let remoteCommand = TealiumRemoteCommand(commandId: "hello",
                                                 description: "test") { response in
                                                    if TealiumHelper.shared.enableHelperLogs {
//                                                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
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
//        self.tealium?.leaveTrace(killVisitorSession: true)
        self.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
            
        self.tealium?.persistentData()?.deleteData(forKeys: ["user_name", "testPersistentKey", "newPersistentKey"])
            
                            self.tealium?.persistentData()?.add(data: ["newPersistentKey": "testPersistentValue"])
                            self.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])

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
        })
    }

    func trackView(title: String, data: [String: Any]?) {
        tealium?.trackView(title: title,
                       data: data,
                       completion: { (success, info, error) in
                        // Optional post processing
                        if self.enableHelperLogs == false {
                            return
                        }
        })

    }
    
    func joinTrace(_ traceID: String) {
        self.tealium?.joinTrace(traceId: traceID)
    }

    func leaveTrace() {
        self.tealium?.leaveTrace()
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

extension TealiumHelper: TealiumVisitorServiceDelegate {
    func profileDidUpdate(profile: TealiumVisitorProfile?) {
        guard let profile = profile else {
            return
        }
        if let json = try? JSONEncoder().encode(profile), let string = String(data: json, encoding: .utf8) {
            print(string)
        }
    }
    
}
