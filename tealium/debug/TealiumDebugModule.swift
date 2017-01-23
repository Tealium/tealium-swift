//
//  TealiumDebugModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

extension TealiumConfig {
    
    func asDictionary() -> [String : Any] {
        
        var dictionary : [String:Any] = [
            "account": self.account as Any,
            "profile": self.profile as Any,
            "environment": self.environment as Any
        ]
        
        dictionary["optionalData"] = self.optionalData
        
        return dictionary
    }
    
    func setDebugQueueSize(_ size: Int) {
       
        self.optionalData += [TealiumDebugKey.debugQueueSize: size]
   
    }
    
    func setDebugPort(_ port: Int) {
     
        self.optionalData += [TealiumDebugKey.debugPort: port]
    }
    
}

 
class TealiumDebugModule : TealiumModule {
    
    let server = TealiumDebugServer()
    
    override func moduleConfig() -> TealiumModuleConfig {
        
        return TealiumModuleConfig(name: TealiumDebugKey.moduleName,
                                   priority: 150,
                                   build: 2,
                                   enabled: true)
        
    }
    
    override func enable(config:TealiumConfig) {
    
        var _port = 8080
        
        if let threshold = config.optionalData[TealiumDebugKey.debugQueueSize] {
            server.queueMax = threshold as! Int
        
        }
        
        if let port = config.optionalData[TealiumDebugKey.debugPort] {
            
            _port = port as! Int
        }
        
        do {
            try server.startWithPort(port: _port)
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
        
        self.didFinishReport(fromModule: fromModule, process: process)

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
 

 
