//
//  TealiumHelper.swift
//  WatchPuzzle
//
//  Created by Jason Koo on 11/22/16.
//  Copyright © 2016 Apple. All rights reserved.
//

import Foundation


/// Example of a shared helper to handle all 3rd party tracking services. This
/// paradigm is recommended to reduce burden of future code updates for external services
/// in general.
class TealiumHelper : NSObject {
    
    static let _sharedInstance = TealiumHelper()
    var tealium : Tealium?
    
    class func sharedInstance() -> TealiumHelper {
        
        return _sharedInstance
        
    }
    
    func start() {

        #if os(iOS)
        let remoteCommand = TealiumRemoteCommand(commandId: "logger",
                                                 description: "test",
                                                 queue: DispatchQueue.main) { (response) in
                                                    
            print("*** TealiumHelper: Remote Command Executed: response:\(response)")
                                                    
        }
        #endif

//        let config = TealiumConfig(account:"tealiummobile",
//                                   profile:"demo",
//                                   environment:"dev",
//                                   datasource:"testDatasource",
//                                   optionalData:nil)
        
        let config = TealiumConfig(account:"services-crouse",
                                   profile:"adobe-acq-test",
                                   environment:"dev",
                                   datasource:"testDatasource",
                                   optionalData:nil)
    
        tealium = Tealium(config: config,
                          completion:{ () in
                            
            // Adding the helper as a delegate to access TealiumDelegate
            //  protocols (see extension below).
            self.tealium?.delegates()?.add(delegate: self)
            self.tealium?.volatileData()?.add(data: ["link_id":"testCommand"])
            
            #if os(iOS)
                guard let remoteCommands = self.tealium?.remoteCommands() else {
                    return
                }
                remoteCommands.add(remoteCommand)
            #endif
        })
                    
    }
    
    func track(title: String, data:[String:Any]?) {
    
        tealium?.track(title: title,
                      data: data,
                      completion: { (success, info, error) in
                        
                // Optional post processing
        })
    }
    
    func trackView(title: String, data:[String:Any]?) {
        
        tealium?.track(type: .view,
                       title: title,
                       data: data,
                       completion: { (success, info, error) in
                        
                // Optional post processing
        })
    
    }
    
}

extension TealiumHelper : TealiumDelegate {

    func tealiumShouldTrack(data: [String : Any]) -> Bool {
        return true
    }
    
    func tealiumTrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
        
        print("\n*** Tealium Helper: Tealium Delegate : tealiumTrackCompleted *** Track finished. Was successful:\(success)\nInfo:\(info as AnyObject)\((error != nil) ? "\nError:\(String(describing:error))":"")")
        
    }
}
