//
//  TealiumAppDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation


/// Module to add app related data to track calls.
class TealiumAppDataModule : TealiumModule {
    
    var persistentDataManager : TealiumPersistentData?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumAppDataKey.moduleName,
                                   priority: 500,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        let uniqueId = TealiumPersistentData.uniqueId(forConfig: config,
                                                      module: self,
                                                      additionalIdentifier: nil)
        
        persistentDataManager = TealiumPersistentData.init(uniqueId: uniqueId)
        
        // Load new persistent data
        if persistentDataManager?.persistentDataCache.isEmpty == true {
            let uuid = newUuid()
            let newData = newPersistentData(forUuid: uuid)
            persistentDataManager?.add(data: newData)
        }
        
        didFinishEnable(config: config)
        
    }
    
    override func disable() {
        
        persistentDataManager = nil
        
        didFinishDisable()
    }
    
    override func track(_ track: TealiumTrack) {
        
        var newData = [String:Any]()
        if let appData = persistentDataManager?.persistentDataCache {
            newData += appData
        }
        newData += track.data
        
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
        
    }
    
    // MARK:
    // MARK: INTERNAL
    // TODO: Migrate to it's own class when additiona data variables are added.
    
    
    func newUuid() -> String {
        
        return UUID.init().uuidString
        
    }
    
    func visitorId(fromUuid: String) -> String {
        
        return fromUuid.replacingOccurrences(of: "-", with: "")
        
    }
    
    
    /// Prepares new Tealium default App related data. Legacy Visitor Id data
    /// is set here as it based off app_uuid.
    ///
    /// - Parameter forUuid: The uuid string to use for new persistent data.
    /// - Returns: A [String:Any] dictionary.
    func newPersistentData(forUuid: String) -> [String:Any]{
        
        let vid = visitorId(fromUuid: forUuid)
        
        let data = [
            TealiumAppDataKey.uuid: forUuid,
            TealiumAppDataKey.visitorId: vid,
            TealiumAppDataKey.legacyVid: vid
        ]
        
        return data as [String : Any]
    }
    
    
}
