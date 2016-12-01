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
    fileprivate var tealium : Tealium
    
    class func sharedInstance() -> TealiumHelper {
        
        return _sharedInstance
        
    }
    
    override init() {
        tealium = Tealium(config: defaultTealiumConfig)
    }
    
    func track(title: String, data:[String:AnyObject]?) {
    
        tealium.track(title: title,
                      data: data,
                      completion: { (success, info, error) in
                        
            print("*** TRACK COMPLETION HANDLER *** Track finished.\nSuccessful:\(success) \nCall info:\(info)")
                        
        })
    }
    
}
