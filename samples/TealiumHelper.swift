//
//  TealiumHelper.swift
//
//  Created by Jason Koo on 11/22/16.
//  Modified by Craig Rouse 22/11/17
//  Copyright © 2017 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

extension String: Error { }

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
@objc class TealiumHelper: NSObject {

    static let shared: TealiumHelper = {
        let helper = TealiumHelper()
        helper.start()
        return helper
    }()
    
    var tealium: Tealium?
    var enableHelperLogs = true

    override private init() {

    }

    @objc func start() {

        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "a1b2c3",
                                   optionalData: nil)

        // OPTIONALLY set log level
        config.setLogLevel(logLevel: .verbose)
        // OPTIONALLY add an external delegate
        config.addDelegate(self)
        config.setInitialUserConsentStatus(.consented)
        // OPTIONALLY disable a particular module by name
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking", "collect"])
        config.setModulesList(list)
      
        tealium = Tealium(config: config) { responses in
            self.tealium?.consentManager()?.setUserConsentStatus(.consented)
                            // Optional processing post init.
                            // OPTIONALLY implement Remote Commands.
                            #if os(iOS)
                            let remoteCommand = TealiumRemoteCommand(commandId: "logger",
                                                                     description: "test") { response in


                    if TealiumHelper.shared.enableHelperLogs {
                        print("*** TealiumHelper: Remote Command Executed: response:\(response)")
                    }

                }

                // this must be done inside the Tealium init callback, otherwise remotecommands won't be avaialable
                if let remoteCommands = self.tealium?.remoteCommands() {
                    remoteCommands.add(remoteCommand)
                } else {
                    return
                }

            #endif
        }


        // example showing persistent data
        self.tealium?.persistentData()?.add(data: ["testPersistentKey": "testPersistentValue"])
        // example showing volatile data
        self.tealium?.volatileData()?.add(data: ["testVolatileKey": "testVolatileValue"])

        // process a tracking call on the background queue
        // example tracking call - not required in production
        DispatchQueue.global(qos: .background).async {
            self.tealium?.track(title: "HelperReady_BG_Queue")
        }
        // example tracking call - not required in production
        self.tealium?.track(title: "HelperReady")
    }

    // track an event
    @objc func track(title: String, data: [String: Any]?) {

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

    // track a screen view
    @objc func trackView(title: String, data: [String: Any]?) {

        tealium?.trackView(title: title,
                           data: data,
                           completion: { (success, info, error) in

                               // Optional post processing
                               // Alternatively, monitoring track completions can be done here vs. using the delegate module's callbacks.
                               if self.enableHelperLogs == false {
                                   return
                               }
                               print("*** TealiumHelper: view completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")

                           })

    }

    @objc func crash() {
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
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing: error))" : "")")
    }
}
