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
        
        var trackData = [String:Any]()
       
        
        trackData += (track.data)
        
        if let trackInfo = track.info {
          
            trackData =  buildDebugTrackData(trackData, trackInfo: trackInfo)
            
        }
        
        
        server.addToDebugQueue(trackData)
        server.serveTrack()
    }

    

    func buildDebugTrackData(_ trackData:[String: Any], trackInfo: [String: Any]?) -> [String: Any] {
        var debugData = [String: Any]()
        
        debugData["type"] = "track" as Any?
        debugData["data"] = trackData as Any
      
        guard let trackInfo = trackInfo else{
            return debugData
        }
        
        debugData["info"] = trackInfo as Any

        return debugData
        
    }
 
}

 
 extension TealiumConfig {
    func asDictionary() -> [String : Any] {
    
        
        var dictionary : [String:Any] = [
            "account": self.account as Any,
            "profile": self.profile as Any,
            "environment": self.environment as Any
        ]
        
        if self.optionalData != nil {
            dictionary["optionalData"] = self.optionalData as Any?
        }
        
        
    return dictionary
    }
    
 }
