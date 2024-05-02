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
    public var remoteCommands: RemoteCommandsManagerProtocol
    var reservedCommandsAdded = false
    let disposeBag = TealiumDisposeBag()

    /// Provided for unit testing￼.
    ///
    /// - Parameter remoteCommands: Class instance conforming to `RemoteCommandsManagerProtocol`
    convenience init (context: TealiumContext,
                      delegate: ModuleDelegate,
                      remoteCommands: RemoteCommandsManagerProtocol? = nil) {
        self.init(context: context, delegate: delegate) { _ in }
        self.remoteCommands = remoteCommands ?? self.remoteCommands
    }

    /// Initializes the module
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion` block to be called when init is finished
    public required init(context: TealiumContext, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = context.config
        remoteCommands = RemoteCommandsManager(config: config, delegate: delegate)
        updateReservedCommands(config: config)
        addCommands(from: config)
        remoteCommands.onCommandsChanged.subscribe { commands in
            let data = [TealiumDataKey.remoteCommands: commands.map { $0.nameAndVersion }]
            context.dataLayer?.add(data: data,
                                   expiry: Expiry.untilRestart)
        }.toDisposeBag(disposeBag)
    }

    /// Allows Remote Commands to be added from the TealiumConfig object.
    /// ￼
    /// - Parameter config: `TealiumConfig` object containing Remote Commands
    private func addCommands(from config: TealiumConfig) {
        if let commands = config.remoteCommands {
            for command in commands {
                self.remoteCommands.add(command)
            }
        }
    }

    /// Identifies if any built-in Remote Commands should be disabled.
    /// ￼
    /// - Parameter config: `TealiumConfig` object containing flags indicating which built-in commands should be disabled.
    func updateReservedCommands(config: TealiumConfig) {
        guard reservedCommandsAdded == false else {
            return
        }
        var shouldDisable = false
        if let shouldDisableSetting = config.options[TealiumConfigKey.disableHTTP] as? Bool {
            shouldDisable = shouldDisableSetting
        }
        if shouldDisable == true {
            remoteCommands.remove(commandWithId: RemoteCommandsKey.commandId)
        } else if remoteCommands.webviewCommands[RemoteCommandsKey.commandId] == nil {
            let httpCommand = RemoteHTTPCommand.create(with: remoteCommands.moduleDelegate, urlSession: remoteCommands.urlSession )
            remoteCommands.add(httpCommand)
        }
        reservedCommandsAdded = true
    }

    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
        switch request {
        case let request as TealiumRemoteCommandRequest:
            self.remoteCommands.trigger(command: .webview,
                                        with: request.data,
                                        completion: completion)
        case let request as TealiumRemoteAPIRequest:
            self.remoteCommands.jsonCommands.forEach { command in
                self.remoteCommands.refresh(command)
            }
            self.remoteCommands.trigger(command: .JSON,
                                        with: request.trackRequest.trackDictionary,
                                        completion: completion)
        default:
            break
        }

    }
}
#endif
