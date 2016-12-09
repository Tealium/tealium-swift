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
                                   priority: 200,
                                   build: 1,
                                   enabled: true)
        
    }
    
    override func enable(config:TealiumConfig) {
        
        server.start(config: config)
        
        super.enable(config: config)

    }
    
    override func disable() {
        
        server.stop()
        
        super.disable()

    }
    
    override func track(_ track: TealiumTrack) {
        
        var newData = [String:AnyObject]()
        
        if let volatileData = self.volatileData?.getData() {
            newData += volatileData
        }
        
        newData += track.data
        
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
    
}

 extension TealiumModuleConfig : CustomStringConvertible {
    var description: String{
        return "name: \(self.name) priority: \(self.priority) enabled: \(self.enabled)" as String
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
