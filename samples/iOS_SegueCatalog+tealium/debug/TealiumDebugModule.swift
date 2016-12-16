 //
//  TealiumDebugModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

class TealiumDebugModule : TealiumModule {
    
    let server = TealiumDebugServer()
    
    override func moduleConfig() -> TealiumModuleConfig {
        
        return TealiumModuleConfig(name: TealiumDebugKey.moduleName,
                                   priority: 2000,
                                   build: 1,
                                   enabled: true)
        
    }
    
    override func enable(config:TealiumConfig) {
        //was passing config
        
        server.start()
        server.addToDebugQueue(config.asDictionary())
        super.enable(config: config)

    }
    
    override func disable() {
        
        server.stop()
        
        super.disable()

    }
    
    override func track(_ track: TealiumTrack) {
        
        var trackData = [String:AnyObject]()
       
        
        trackData += (track.data)
        
        if let trackInfo = track.info {
          
            trackData =  buildDebugTrackData(trackData, trackInfo: trackInfo)
            
        }
        
        
        server.addToDebugQueue(trackData)
        server.serveTrack()
    }

    

    func buildDebugTrackData(_ trackData:[String: AnyObject], trackInfo: [String: AnyObject]?) -> [String: AnyObject] {
        var debugData = [String: AnyObject]()
        
        debugData["type"] = "track" as AnyObject?
        debugData["data"] = trackData as AnyObject
      
        guard let trackInfo = trackInfo else{
            return debugData
        }
        
        debugData["info"] = trackInfo as AnyObject

        return debugData
        
    }
 
}

 
 extension TealiumConfig {
    func asDictionary() -> [String : AnyObject] {
    
        
        var dictionary : [String:AnyObject] = [
            "account": self.account as AnyObject,
            "profile": self.profile as AnyObject,
            "environment": self.environment as AnyObject
        ]
        
        if self.optionalData != nil {
            dictionary["optionalData"] = self.optionalData as AnyObject?
        }
        
        
    return dictionary
    }
    
 }
