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
                                   priority: 150,
                                   build: 1,
                                   enabled: true)
        
    }
    
    override func enable(config:TealiumConfig) {
        
        do {
            try server.start()
            
            server.add(getConfigInfo(config))
            
            printAddress()
            
            self.didFinishEnable(config: config)
            
        } catch let e {
         
            self.didFailToEnable(config: config,
                                 error: e)
        }

    }
    
    func printAddress() {
        
        var message = "For Debugging use port: "
        do {
            let port = try server.server.port()
            message += "\(port)"
        } catch {
            
        }
        print(message)
        
    }
    
    override func disable() {
        
        server.stop()
        
        self.didFinishDisable()

    }

    override func handleReport(fromModule: TealiumModule, process: TealiumProcess) {
        
        if process.type != .track ||
            fromModule == self ||
            process.track == nil ||
            process.track?.info == nil {
            didFinishReport(fromModule: fromModule,
                            process: process)
            return
        }
        
        let trackData = getDebugTrackInfo(process.track!.info!)
        server.add(trackData)

    }

    func getConfigInfo(_ config: TealiumConfig  ) -> [String: Any] {
        
        let configDict = ["type":"config",
                         "info": config.asDictionary()] as [String : Any]

        return configDict
        
    }

    func getDebugTrackInfo(_ trackInfo: [String: Any]) -> [String: Any] {
        
        var debugData = [String: Any]()
        
        debugData["type"] = "track"
        debugData["info"] = trackInfo

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
 
 
