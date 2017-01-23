//
//  TealiumVolatileDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

extension Tealium {
    
    public func volatileData() -> TealiumVolatileData? {
        
        guard let module = modulesManager.getModule(forName: TealiumVolatileDataKey.moduleName) as? TealiumVolatileDataModule else {
            return nil
        }
        
        return module.volatileData
        
    }
    
}


/// Module for adding session long (from wake until terminate) data varables to all track calls.
class TealiumVolatileDataModule : TealiumModule {
    
    var volatileData : TealiumVolatileData?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumVolatileDataKey.moduleName,
                                   priority: 700,
                                   build: 1,
                                   enabled: true)
    }

    override func enable(config: TealiumConfig) {
        
        if volatileData == nil {
            volatileData = TealiumVolatileData()
            let currentStaticData : [String:Any] = [TealiumKey.account:config.account,
                                                    TealiumKey.profile:config.profile,
                                                    TealiumKey.environment:config.environment,
                                                    TealiumKey.libraryName:TealiumValue.libraryName,
                                                    TealiumKey.libraryVersion:TealiumValue.libraryVersion]
          
            volatileData?.add(data: currentStaticData)
        }
        
        didFinishEnable(config: config)
        
    }
    
    override func disable() {
        volatileData = nil
        
        didFinishDisable()
    }
    
    override func track(_ track: TealiumTrack) {
        var newData = [String:Any]()
        
        if let volatileData = self.volatileData?.getData() {
            newData += volatileData
        }
        
        newData += track.data
        
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
    }
    
}
