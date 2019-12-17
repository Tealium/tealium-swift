//
//  TealiumRemoteCommandsModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//
//  See https://github.com/Tealium/tagbridge for spec reference.

import Foundation
#if remotecommands
import TealiumCore
#endif

public class TealiumRemoteCommandsModule: TealiumModule {

    public var remoteCommands: TealiumRemoteCommands?
    var observer: NSObjectProtocol?

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumRemoteCommandsKey.moduleName,
                                   priority: 1200,
                                   build: 3,
                                   enabled: true)
    }

    /// Enables the module.
    ///￼
    /// - Parameter request: `TealiumEnableRequest` from which to enable the module
    override public func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config
        remoteCommands = TealiumRemoteCommands()
        remoteCommands?.enable()
        updateReservedCommands(config: config)
        self.addCommandsFromConfig(config)
        didFinish(request)
    }

    /// Allows Remote Commands to be added from the TealiumConfig object.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommandsFromConfig(_ config: TealiumConfig) {
        if let commands = config.getRemoteCommands() {
            for command in commands {
                self.remoteCommands?.add(command)
            }
        }
    }

    /// Enables listeners for notifications from the Tag Management module (WebView).
    func enableNotifications() {
        self.observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: TealiumKey.tagmanagementNotification), object: nil, queue: OperationQueue.main) { [weak self] in
            guard let self = self else {
                return
            }
            self.remoteCommands?.triggerCommandFrom(notification: $0)
        }
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing flags indicating which built-in commands should be disabled.
    func updateReservedCommands(config: TealiumConfig) {
        // Default option
        var shouldDisable = false

        if let shouldDisableSetting = config.optionalData[TealiumRemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }

        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: TealiumRemoteHTTPCommandKey.commandId)
        } else if remoteCommands?.commands.commandForId(TealiumRemoteHTTPCommandKey.commandId) == nil {
            let httpCommand = TealiumRemoteHTTPCommand.httpCommand()
            remoteCommands?.add(httpCommand)
            enableNotifications()
        }
        // No further processing required - HTTP remote command already up.
    }

    /// Disables the Remote Commands module.
    ///￼
    /// - Parameter request: `TealiumDisableRequest` indicating that the module should be disabled
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        remoteCommands?.disable()
        remoteCommands = nil
        didFinish(request)
    }

    deinit {
        if let observer = self.observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
