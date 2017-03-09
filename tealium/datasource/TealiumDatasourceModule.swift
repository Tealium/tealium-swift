//
//  TealiumDatasourceModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/8/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumDatasourceKey {
    static let moduleName = "datasource"
    static let config = "com.tealium.datasource"
    static let variable = "tealium_datasource"
}

extension TealiumConfig {

    convenience init(account:String,
                     profile:String,
                     environment:String,
                     datasource:String?,
                     optionalData:[String:Any]?) {
        
        var newOptionalData = [String:Any]()
        if let initialOptionalData = optionalData {
            newOptionalData += initialOptionalData
        }
        if let initialDatasource = datasource {
            newOptionalData[TealiumDatasourceKey.config] = initialDatasource
        }
        self.init(account:account,
                  profile:profile,
                  environment:environment,
                  optionalData:newOptionalData)
        
    }
    
}

class TealiumDatasourceModule : TealiumModule {
    
    var datasource : String?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDatasourceKey.moduleName,
                                   priority: 550,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        if let datasourceString = config.optionalData[TealiumDatasourceKey.config] as? String {
            datasource = datasourceString
        }
        
        didFinishEnable(config: config)
    }
    
    override func track(_ track: TealiumTrack) {
        
        guard let datasource = self.datasource else {
            didFinishTrack(track)
            return
        }
        
        var newData : [String:Any] = [TealiumDatasourceKey.variable:datasource]
        newData += track.data
        let newTrack = TealiumTrack(data: newData,
                                    info: track.info,
                                    completion: track.completion)
        
        didFinishTrack(newTrack)
    }

    
}
