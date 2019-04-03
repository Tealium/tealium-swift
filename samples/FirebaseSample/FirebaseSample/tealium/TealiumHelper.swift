//
//  TealiumHelper.swift
//
//  Created by Jason Koo on 11/22/16.
//  Modified by Craig Rouse 22/11/17
//  Copyright © 2017 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
class TealiumHelper {

    static let shared = TealiumHelper()
    var tealium: Tealium?
    var enableHelperLogs = true

    func start() {
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "firebase-analytics",
                                   environment: "dev",
                                   datasource: "test12",
                                   optionalData: nil)
        config.setLogLevel(logLevel: .verbose)
        config.addDelegate(self)
        tealium = Tealium(config: config, enableCompletion: { (response) in
            // Remote Commands.
            #if os(iOS)
                guard let remoteCommands = self.tealium?.remoteCommands() else {
                    return
                }
                let firebaseCommand = FirebaseCommands.firebaseCommand()
                remoteCommands.add(firebaseCommand)
            #endif
        })
        // process a tracking call on the background queue
        DispatchQueue.global(qos: .background).async {
            self.tealium?.track(title: "HelperReady_BG_Queue")
        }
        // example tracking call - not required in production
        self.tealium?.track(title: "HelperReady")
    }

    /// track an event
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

    /// track a screen view
    func trackView(title: String, data: [String: Any]?) {
        tealium?.trackView(title: title,
                           data: data,
                           completion: { (success, info, error) in
                               // Optional post processing. Alternatively, monitoring track completions can be done here vs. using the delegate module's callbacks.
                               if self.enableHelperLogs == false {
                                   return
                               }
                               print("*** TealiumHelper: view completed:\n\(success)\n\(String(describing: info))\n\(String(describing: error))")

                           })
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
