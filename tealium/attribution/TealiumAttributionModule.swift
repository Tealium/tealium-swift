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

/**
 Module to automatically add IDFA vendor identifier to track calls. Does NOT work with watchOS.
 */
class TealiumAttributionModule : TealiumModule {
    
    var advertisingId : String?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAttributionKey.moduleName,
                                   priority: 400,
                                   build: 2,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        // UIKit is not available for testing
        #if TEST
        #else
            // UIDevice is also not available on watchOS
            #if os(watchOS)
            #else
                advertisingId = UIDevice.current.identifierForVendor?.uuidString
            #endif
        #endif
        didFinishEnable(config: config)
    }
    
    override func disable() {
        
        advertisingId = nil
        
        didFinishDisable()
    }
    
    override func track(_ track: TealiumTrack) {
     
        // Add idfa to data - NOTE: This requires additional requirements when
        // submitting to Apple's App Review process, see -
        // https://developer.apple.com/library/content/documentation/LanguagesUtilities/Conceptual/iTunesConnect_Guide/Chapters/SubmittingTheApp.html#//apple_ref/doc/uid/TP40011225-CH33-SW8
        
        guard let advertisingId = self.advertisingId else {
            
            // Module disabled - ignore IDFA request
            
            didFinishTrack(track)
            return
        }
        
        // Module enabled - add IDFA info to data
        
        var newData = [TealiumAttributionKey.advertisingId : advertisingId as Any]
        
        newData += track.data
        
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
        
    }

}
