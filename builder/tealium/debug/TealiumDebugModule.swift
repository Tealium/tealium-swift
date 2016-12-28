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
        
        server.start()
        
        server.addToDebugQueue(getConfigInfo(config))

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
          
            trackData =  getDebugTrackInfo(trackData, trackInfo: trackInfo)            
        }
        
        server.addToDebugQueue(trackData)
        server.serveTrack()
    }


    func getConfigInfo(_ config: TealiumConfig  ) -> [String: Any] {
        
        let configDict = ["type":"config_update",
                         "data": config.asDictionary(),
                         "info": ""] as [String : Any]

        return configDict
        
    }

    func getDebugTrackInfo(_ trackData:[String: Any], trackInfo: [String: Any]?) -> [String: Any] {
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
