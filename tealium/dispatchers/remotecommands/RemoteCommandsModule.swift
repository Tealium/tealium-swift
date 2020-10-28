//
//  RemoteCommandsModule.swift
//  tealium-swift
//
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
    public var isReady: Bool = false
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
        remoteCommands = remoteCommands ?? RemoteCommandsManager(config: config, delegate: delegate)
        updateReservedCommands(config: config)
        addCommands(from: config)
    }

    public func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            let existingWebViewCommands = self.remoteCommands?.webviewCommands
            let existingJSONCommands = self.remoteCommands?.jsonCommands
            if let newWebViewCommands = newConfig.remoteCommands, newWebViewCommands.count > 0 {
                existingWebViewCommands?.forEach {
                    newConfig.addRemoteCommand($0)
                }
            }
            if let newJSONCommands = newConfig.remoteCommands, newJSONCommands.count > 0 {
                existingJSONCommands?.forEach {
                    newConfig.addRemoteCommand($0)
                }
            }
        }
    }
    /// Allows Remote Commands to be added from the TealiumConfig object.
    ///￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommands(from config: TealiumConfig) {
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
        var shouldDisable = false
        if let shouldDisableSetting = config.options[RemoteCommandsKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }
        if shouldDisable == true {
            remoteCommands?.remove(commandWithId: RemoteCommandsKey.commandId)
        } else if remoteCommands?.webviewCommands[RemoteCommandsKey.commandId] == nil {
            let httpCommand = RemoteHTTPCommand.create(with: remoteCommands?.moduleDelegate)
            remoteCommands?.add(httpCommand)
        }
        reservedCommandsAdded = true
    }

    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
        switch request {
        case let request as TealiumRemoteCommandRequest:
            self.remoteCommands?.trigger(command: .webview, with: request.data, completion: completion)
        case let request as TealiumRemoteAPIRequest:
            guard let commands = self.remoteCommands else {
                return
            }
            commands.jsonCommands.forEach { command in
                guard let config = command.config,
                      let url = config.commandURL,
                      let name = config.fileName
                else {
                    return
                }
                commands.refresh(command, url: url, file: name)
            }
            commands.trigger(command: .JSON, with: request.trackRequest.trackDictionary, completion: completion)
        default:
            break
        }

    }
}
#endif
