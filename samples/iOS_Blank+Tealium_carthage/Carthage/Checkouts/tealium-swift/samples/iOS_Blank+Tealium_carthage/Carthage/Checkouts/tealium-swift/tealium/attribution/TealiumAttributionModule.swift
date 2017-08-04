//
//  TealiumAttributionModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

#if TEST

import Foundation
    
#else

    #if os(macOS)
    #else
        import UIKit
    #endif
#endif

// MARK:
// MARK: CONSTANTS
public enum TealiumAttributionKey {
    static let moduleName = "attribution"
    static let advertisingId = "device_advertising_id"
}


// MARK:
// MARK: MODULE SUBCLASS
/**
 Module to automatically add IDFA vendor identifier to track calls. Does NOT work with watchOS.
 */
class TealiumAttributionModule : TealiumModule {
    
    var advertisingId : String?
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAttributionKey.moduleName,
                                   priority: 400,
                                   build: 3,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        // UIKit is not available for testing
        #if TEST
        #else
            // UIDevice is also not available on watchOS
            #if os(watchOS)
            #else
                advertisingId = UIDevice.current.identifierForVendor?.uuidString
            #endif
        #endif
        didFinish(request)
    }
    
    override func disable(_ request: TealiumDisableRequest) {
        
        isEnabled = false
        
        advertisingId = nil
        
        didFinish(request)
    }
    
    override func track(_ track: TealiumTrackRequest) {
     
        // Add idfa to data - NOTE: This requires additional requirements when
        // submitting to Apple's App Review process, see -
        // https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8
        
        guard let advertisingId = self.advertisingId else {
            
            // Module disabled - ignore IDFA request
            
            didFinish(track)
            return
        }
        
        // Module enabled - add IDFA info to data
        
        var newData = [TealiumAttributionKey.advertisingId : advertisingId as Any]
        
        newData += track.data
        
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        
        didFinish(newTrack)
        
    }

}
