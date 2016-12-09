 //
//  TealiumModule_Debug.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

class TealiumModule_Debug : TealiumModule {
    
    let server = TealiumDebugServer()
    
    override func moduleConfig() -> TealiumModuleConfig {
        
        return TealiumModuleConfig(name: "debug",
                                   priority: 200,
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
    
    override func track(data: [String : AnyObject],
                        info: [String : AnyObject]?,
                        completion: ((Bool, [String:AnyObject]?, Error?) -> Void)?) {
        
        // TODO: send track calls to debug server
        
        super.track(data: data,
                    info: info,
                    completion: completion)
        
    }
    
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
