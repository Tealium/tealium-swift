//
//  TealiumHelper.swift
//
//  Created by Jason Koo on 11/22/16.
//  Modified by Craig Rouse 22/11/17
//  Copyright © 2017 Tealium. All rights reserved.
//

import Foundation
import TealiumSwift

extension String: Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
/// Note: TealiumHelper class inherits from NSObject to allow @objc annotations and Objective-C interop.
/// If you don't need this, you may omit @objc annotations and NSObject inheritance.
@objc class TealiumHelper: NSObject {
    
    static let shared: TealiumHelper = {
        let helper = TealiumHelper()
        helper.start()
        return helper
    }()
    
    var tealium: Tealium!
    var enableHelperLogs = true
    
    override private init() {
        
    }
    
    @objc func start() {
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "test12",
                                   optionalData: nil)
        
        config.setLogLevel(logLevel: .verbose)
        config.setMemoryReportingEnabled(true)
        
        // OPTIONALLY disable a particular module by name
        let list = TealiumModulesList(isWhitelist: false,
                                      moduleNames: ["autotracking", "collect", "consentmanager"])
        config.setModulesList(list)
        print("*** TealiumHelper: Autotracking disabled.")
        
        // REQUIRED Initialization
        tealium = Tealium(config: config) { response in
            self.tealium.consentManager()?.setUserConsentStatus(.consented)
        }
    }
    
    // track an event
    @objc func track(title: String, data: [String: Any]?) {
        
        tealium.track(title: title,
                       data: data,
                       completion: { _,_,_ in

        })
    }
    
    // track a screen view
    @objc func trackView(title: String, data: [String: Any]?) {
        
        tealium.trackView(title: title,
                           data: data,
                           completion: { _,_,_ in
                            
        })
    }
    
    @objc func joinTrace(traceId: String) {
        tealium.joinTrace(traceId: traceId)
    }
    
    @objc func leaveTrace() {
        tealium.leaveTrace()
    }
}
