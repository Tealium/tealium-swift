//
//  TealiumHelper.swift
//  WatchPuzzle
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation

extension String : Error {}

/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
class TealiumHelper : NSObject {
    
    static let _sharedInstance = TealiumHelper()
    var tealium : Tealium?
    var enableHelperLogs = false
    class func sharedInstance() -> TealiumHelper {
        
        return _sharedInstance
        
    }
    
    func start() {
    
        // REQUIRED Config object for lib
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "demo",
                                   environment: "dev",
                                   datasource: "test12",
                                   optionalData: nil)
        
        // OPTIONALLY set log level
        config.setLogLevel(logLevel: .verbose)
        
        // OPTIONALLY add an external delegate
        config.addDelegate(self)

        config.setDispatchQueue(DispatchQueue.global(qos: .background))
        
        // OPTIONALLY disable a particular module by name
//        let list = TealiumModulesList(isWhitelist: false,
//                                      moduleNames: ["tagmanagement"])
//        config.setModulesList(list)

        // REQUIRED Initialization
        tealium = Tealium(config: config,
                          completion: { (responses) in
                        
                    // Optional processing post init.
                            
        })
        
        tealium?.persistentData()?.add(data: ["testPersistentKey":"testPersistentValue"])
        
        tealium?.volatileData()?.add(data: ["testVolatileKey":"testVolatileValue"])
        
        DispatchQueue.global(qos: .background).async {
            self.tealium?.track(title: "HelperReady_BG_Queue")    
        }
        tealium?.track(title: "HelperReady")
        
        // OPTIONALLY implement Dynamic Triggers.
        #if os(iOS)
            let remoteCommand = TealiumRemoteCommand(commandId: "logger",
                                                     description: "test") { (response) in
                                                        
                if TealiumHelper.sharedInstance().enableHelperLogs {
                    print("*** TealiumHelper: Remote Command Executed: response:\(response)")
                }
                                                        
            }
            guard let remoteCommands = tealium?.remoteCommands() else {
                return
            }
            remoteCommands.add(remoteCommand)
        #endif
        

    }
    
    func track(title: String, data:[String:Any]?) {
    
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
    
    func trackView(title: String, data:[String:Any]?) {
        
        tealium?.track(title: title,
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
    
    func crash() {
        NSException.raise(NSExceptionName(rawValue: "Exception"), format:"This is a test exception", arguments:getVaList(["nil"]))
    }
    
}

extension TealiumHelper : TealiumDelegate {

    
    func tealiumShouldTrack(data: [String : Any]) -> Bool {
        return true
    }
    
    func tealiumTrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
        
        if enableHelperLogs == false {
            return
        }
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing:error))":"")")
        
    }
}
