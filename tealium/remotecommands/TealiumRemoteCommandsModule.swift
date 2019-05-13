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

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumRemoteCommandsKey.moduleName,
                                   priority: 1200,
                                   build: 3,
                                   enabled: true)
    }

    /// Enables the module
    ///
    /// - Parameter request: TealiumEnableRequest from which to enable the module
    override public func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        let config = request.config
        remoteCommands = TealiumRemoteCommands()
        remoteCommands?.queue = config.dispatchQueue()
        remoteCommands?.enable()
        updateReservedCommands(config: config)
        self.addCommandsFromConfig(config)
        didFinish(request)
    }

    /// Allows Remote Commands to be added from the TealiumConfig object
    ///
    /// - Parameter config: TealiumConfig object containing Remote Commands
    private func addCommandsFromConfig(_ config: TealiumConfig) {
        if let commands = config.getRemoteCommands() {
            for command in commands {
                self.remoteCommands?.add(command)
            }
        }
    }

    /// Enables listeners for notifications from the Tag Management module (WebView)
    func enableNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(trigger),
                                               name: NSNotification.Name(rawValue: TealiumKey.tagmanagementNotification),
                                               object: nil)
    }

    /// Triggers a remote command from a URLRequest (usually from WebView)
    ///
    /// - Parameter sender: Notification containing the URLRequest to trigger the Remote Command
    @objc
    func trigger(sender: Notification) {
        guard let request = sender.userInfo?[TealiumKey.tagmanagementNotification] as? URLRequest else {
            return
        }

        _ = remoteCommands?.triggerCommandFrom(request: request)
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    ///
    /// - Parameter config: TealiumConfig object containing flags indicating which built-in commands should be disabled.
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

    /// Disables the Remote Commands module
    ///
    /// - Parameter request: TealiumDisableRequest indicating that the module should be disabled
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        remoteCommands?.disable()
        remoteCommands = nil
        didFinish(request)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
