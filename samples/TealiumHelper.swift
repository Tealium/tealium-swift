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
    fileprivate var tealium : Tealium?
    
    class func sharedInstance() -> TealiumHelper {
        
        return _sharedInstance
        
    }
    
    func start() {
        
            let config = defaultTealiumConfig
        
            tealium = Tealium(config: config,
                              completion:{ () in
                #if AUTOTRACKING
                    self.tealium?.autotracking()?.delegate = self
                #endif
        
            })
            
    }
    
    func track(title: String, data:[String:Any]?) {
    
        tealium?.track(title: title,
                      data: data,
                      completion: { (success, info, error) in
                        
            print("\n*** TRACK COMPLETION HANDLER *** Event Track finished. Was successful:\(success)\n\n Info:\(info as AnyObject)")
                        
        })
    }
    
    func trackView(title: String, data:[String:Any]?) {
        
        tealium?.track(type: .view,
                       title: title,
                       data: data,
                       completion: { (success, info, error) in
                        
                print("\n*** TRACK COMPLETION HANDLER *** View Track finished. Was successful:\(success)\n\n Info:\(info as AnyObject)")
        })
    
    }
    
}

#if AUTOTRACKING
extension TealiumHelper : TealiumAutotrackingDelegate {
    
    func tealiumAutotrackShouldTrack(data: [String : Any]) -> Bool {
        
        // Can add logic to suppress track events for calls with particular data payloads
        
        return true
    }
    
    func tealiumAutotrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
        
        print("\n*** AUTO TRACK COMPLETION HANDLER *** Track finished. Was successful:\(success)\n\n Info:\(info as AnyObject)")

    }
}
#endif
