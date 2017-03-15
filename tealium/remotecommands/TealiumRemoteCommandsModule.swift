//
//  TealiumRemoteCommandsModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandsKey {
    static let moduleName = "remotecommands"
    static let disable = "disable_remote_commands"
}

extension Tealium {
    
    public func remoteCommands() -> TealiumRemoteCommands? {
        
        guard let module = modulesManager.getModule(forName: TealiumRemoteCommandsKey.moduleName) as? TealiumRemoteCommandsModule else {
            return nil
        }
        
        return module.remoteCommands
        
    }
}

extension TealiumConfig {
    
    func disableRemoteCommands() {
        
        optionalData[TealiumRemoteCommandsKey.disable] = true
        
    }
    
}


class TealiumRemoteCommandsModule : TealiumModule {
    
    var remoteCommands : TealiumRemoteCommands?
    
    override func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumRemoteCommandsKey.moduleName,
                                   priority: 1200,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(config: TealiumConfig) {
        
        
        if config.optionalData[TealiumRemoteCommandsKey.disable] as? Bool == true {
            remoteCommands?.disable()
            remoteCommands = nil
        } else {
            remoteCommands = TealiumRemoteCommands()
        }
        
        self.didFinishEnable(config: config)
        
    }
    
    override func disable() {
        
        remoteCommands?.disable()
        remoteCommands = nil
        self.didFinishDisable()
        
    }
    
}
