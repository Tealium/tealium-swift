//
//  RemoteCommandProtocols.swift
//  TealiumRemoteCommands
//
//  Created by Christina S on 6/2/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public protocol RemoteCommandsManagerProtocol {
    var moduleDelegate: ModuleDelegate? { get set }
    var commands: RemoteCommandArray { get set }
    func add(_ remoteCommand: RemoteCommandProtocol)
    func remove(commandWithId: String)
    func removeAll()
    func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError?
    func triggerCommand(with data: [String: Any])
}

public protocol RemoteCommandProtocol {
    var commandId: String { get }
    var remoteCommandCompletion: TealiumRemoteCommandCompletion { get set }
    var delegate: RemoteCommandDelegate? { get set }
    var description: String? { get set }
    func complete(with response: RemoteCommandResponseProtocol)
    static func sendRemoteCommandResponse(for commandId: String,
                                          response: RemoteCommandResponseProtocol,
                                          delegate: ModuleDelegate?)
}

public protocol RemoteCommandResponseProtocol {
    var payload: [String: Any]? { get set }
    var responseId: String? { get }
    var error: Error? { get set }
    var status: Int { get set }
    var data: Data? { get set }
    var urlResponse: URLResponse? { get set }
    var hasCustomCompletionHandler: Bool { get set }
}

public protocol RemoteCommandDelegate: class {

    /// Triggers the completion block registered for a specific remote command
    ///
    /// - Parameters:
    ///     - command: `RemoteCommandProtocol` to be executed
    ///     - response: `RemoteCommandResponseProtocol` object passed back from TiQ. If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///      it must set the "hasCustomCompletionHandler" flag, otherwise the completion notification will be sent automatically
    func remoteCommandRequestsExecution(_ command: RemoteCommandProtocol,
                                        response: RemoteCommandResponseProtocol)
}

#endif
