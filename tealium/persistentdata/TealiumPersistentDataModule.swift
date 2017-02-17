//
//  TealiumDataManagerModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

extension Tealium {

    /**
     Get the Data Manager instance for accessing file persistence and auto data variable APIs.
     */
    public func persistentData() -> TealiumPersistentData? {
        
        guard let module = modulesManager.getModule(forName: TealiumPersistentDataKey.moduleName) as? TealiumPersistentDataModule else {
            return nil
        }
        
        return module.persistentData
        
    }
    
}


/**
 Module for adding publically accessible persistence data capability.
 */
class TealiumPersistentDataModule : TealiumModule {
    
    var persistentData : TealiumPersistentData?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return  TealiumModuleConfig(name: TealiumPersistentDataKey.moduleName,
                                    priority: 600,
                                    build: 1,
                                    enabled: true)
    }
    
    override func enable(config:TealiumConfig) {
        
        let uniqueId = "\(config.account).\(config.profile).\(config.environment)"
        
        self.persistentData = TealiumPersistentData(uniqueId: uniqueId)

        didFinishEnable(config: config)
        
    }
    
    override func disable() {
        
        persistentData = nil
        
        didFinishDisable()
    }
    
    override func track(_ track: TealiumTrack) {
        
        guard let persistentData = self.persistentData else {
            
            didFailToTrack(track,
                           error: TealiumPersistentDataModuleError.didNotInitialize)
            
            // Return completion block
            track.completion?(false, nil, TealiumPersistentDataModuleError.didNotInitialize)
            
            return
        }
        
        var dataDictionary = [String:Any]()
        
        dataDictionary += persistentData.getData()
        dataDictionary += track.data
        
        let newTrack = TealiumTrack(data: dataDictionary,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
        
    }
    
}
