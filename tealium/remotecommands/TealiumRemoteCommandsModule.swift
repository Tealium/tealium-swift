//
//  TealiumRemoteCommandsModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//
//  See https://github.com/Tealium/tagbridge for spec reference.

import Foundation

enum TealiumRemoteCommandsKey {
    static let moduleName = "remotecommands"
    static let disable = "disable_remote_commands"
    static let disableHTTP = "disable_remote_command_http"
    static let tagmanagementNotification = "com.tealium.tagmanagement.urlrequest"
}

enum TealiumRemoteCommandsModuleError: LocalizedError {
    case wasDisabled
    public var errorDescription: String? {
        switch self {
        case .wasDisabled:
            return NSLocalizedString("Module disabled by config setting.", comment: "RemoteCommandModuleDisabled")
        }
    }
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
    
    func disableRemoteHTTPCommand() {
        
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = true
    }
    
    func enableRemoteCommands() {
        
        optionalData[TealiumRemoteCommandsKey.disable] = false
        
    }
    
    func enableRemoteHTTPCommand() {
        
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = false
        
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
        
        var shouldDisable = false
        if let shouldDisableSetting = config.optionalData[TealiumRemoteCommandsKey.disable] as? Bool {
            shouldDisable = shouldDisableSetting
        }
        
        if shouldDisable == true {
            self.updateReserveCommands(config: config)
            remoteCommands?.disable()
            self.didFailToEnable(config: config, error: TealiumRemoteCommandsModuleError.wasDisabled)
        } else {
            remoteCommands = TealiumRemoteCommands()
            remoteCommands?.enable()
            self.updateReserveCommands(config: config)
            self.didFinishEnable(config: config)
        }
        

    }
    
    func enableNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trigger),
                                               name:NSNotification.Name(rawValue: TealiumRemoteCommandsKey.tagmanagementNotification),
                                               object: nil)
    }
    
    @objc func trigger(sender: Notification){
        
        guard let request = sender.userInfo?[TealiumRemoteCommandsKey.tagmanagementNotification] as? URLRequest else {
            return
        }
        // TODO: Error handling
        let _ = remoteCommands?.triggerCommandFrom(request: request)
    }
    
    func updateReserveCommands(config: TealiumConfig) {
        
        var shouldDisable = false
        if let shouldDisableSetting = config.optionalData[TealiumRemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }
        
        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: TealiumRemoteHTTPCommandKey.commandId)
        } else if remoteCommands?.commands.commandForId(TealiumRemoteHTTPCommandKey.commandId) == nil {
            let httpCommand = TealiumRemoteHTTPCommand.httpCommand(forQueue: DispatchQueue.main)
            remoteCommands?.add(httpCommand)
            enableNotifications()
        }
        // No further processing required - HTTP remote command already up.

    }
    
    override func disable() {
        
        remoteCommands?.disable()
        remoteCommands = nil
        self.didFinishDisable()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
