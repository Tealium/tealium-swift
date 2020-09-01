//
//  TealiumRemoteCommandsModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public class RemoteCommandsModule: Dispatcher {

    public var id: String = ModuleNames.remotecommands
    public var config: TealiumConfig
    public var remoteCommands: RemoteCommandsManagerProtocol?
    var reservedCommandsAdded = false

    /// Provided for unit testing￼.
    ///
    /// - Parameter remoteCommands: Class instance conforming to `RemoteCommandsManagerProtocol`
    convenience init (config: TealiumConfig,
                      delegate: ModuleDelegate,
                      remoteCommands: RemoteCommandsManagerProtocol? = nil) {
        self.init(config: config, delegate: delegate) { _ in }
        self.remoteCommands = remoteCommands
    }

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    public required init(config: TealiumConfig, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
        remoteCommands = remoteCommands ?? RemoteCommandsManager(delegate: delegate)
        updateReservedCommands(config: config)
        addCommandsFromConfig(config)
    }

    public func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            let existingCommands = self.remoteCommands?.commands
            if let newCommands = newConfig.remoteCommands, newCommands.count > 0 {
                existingCommands?.forEach {
                    newConfig.addRemoteCommand($0)
                }
            }
        }
    }

    /// Allows Remote Commands to be added from the TealiumConfig object.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommandsFromConfig(_ config: TealiumConfig) {
        if let commands = config.remoteCommands {
            for command in commands {
                self.remoteCommands?.add(command)
            }
        }
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing flags indicating which built-in commands should be disabled.
    func updateReservedCommands(config: TealiumConfig) {
        guard reservedCommandsAdded == false else {
            return
        }
        // Default option
        var shouldDisable = false

        if let shouldDisableSetting = config.options[RemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }

        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: RemoteCommandsKey.commandId)
        } else if remoteCommands?.commands[RemoteCommandsKey.commandId] == nil {
            let httpCommand = RemoteHTTPCommand.create(with: remoteCommands?.moduleDelegate)
            remoteCommands?.add(httpCommand)
        }
        reservedCommandsAdded = true
        // No further processing required - HTTP remote command already up.
    }

    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
        guard let incoming = request as? TealiumRemoteCommandRequest else {
            return
        }
        self.remoteCommands?.triggerCommand(with: incoming.data)
    }

}
#endif
