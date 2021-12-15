//
//  RemoteCommandProtocols.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public protocol RemoteCommandsManagerProtocol {
    var onCommandsChanged: TealiumObservable<[RemoteCommandProtocol]> { get }
    var jsonCommands: [RemoteCommandProtocol] { get set }
    var webviewCommands: [RemoteCommandProtocol] { get set }
    var moduleDelegate: ModuleDelegate? { get set }
    var urlSession: URLSessionProtocol { get }
    func add(_ remoteCommand: RemoteCommandProtocol)
    func refresh(_ command: RemoteCommandProtocol, url: URL, file: String)
    func remove(commandWithId: String)
    func remove(jsonCommand name: String)
    func removeAll()
    func trigger(command type: SimpleCommandType, with data: [String: Any], completion: ModuleCompletion?)
    func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError?
}

public protocol RemoteCommandProtocol {
    var commandId: String { get }
    var type: RemoteCommandType { get set }
    var config: RemoteCommandConfig? { get set }
    var completion: (_ response: RemoteCommandResponseProtocol) -> Void { get set }
    var delegate: RemoteCommandDelegate? { get set }
    var description: String? { get set }
    func complete(with trackData: [String: Any],
                  config: RemoteCommandConfig,
                  completion: ModuleCompletion?)
    func completeWith(response: RemoteCommandResponseProtocol)
    static func sendRemoteCommandResponse(for commandId: String,
                                          response: RemoteCommandResponseProtocol,
                                          delegate: ModuleDelegate?)

    var name: String { get }
    var version: String? { get }
}

public extension RemoteCommandProtocol {

    internal var nameAndVersion: String {
        var suffix = ""
        if let version = self.version {
            suffix += "-\(version)"
        }
        return self.name + suffix
    }

    var name: String {
        return commandId
    }

    var version: String? {
        versionForObject(self)
    }
}

func versionForObject(_ obj: Any) -> String? {
    guard let aClass = Swift.type(of: obj) as? AnyClass else {
        return nil
    }
    return versionString(bundle: Bundle(for: aClass))
}

func versionString(bundle: Bundle) -> String? {
    guard let dictionary = bundle.infoDictionary,
          let version = dictionary["CFBundleShortVersionString"] as? String else {
        return nil
    }
    return "\(version)"
}

public protocol RemoteCommandResponseProtocol {
    var payload: [String: Any]? { get set }
    var error: Error? { get set }
    var status: Int? { get set }
    var data: Data? { get set }
    var hasCustomCompletionHandler: Bool { get set }
}

public protocol RemoteCommandDelegate: AnyObject {

    /// Triggers the completion block registered for a specific remote command
    ///
    /// - Parameters:
    ///     - command: `TealiumRemoteCommand` to be executed
    ///     - response: `RemoteCommandResponse` object passed back from TiQ. If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///      it must set the "hasCustomCompletionHandler" flag, otherwise the completion notification will be sent automatically
    func remoteCommandRequestsExecution(_ command: RemoteCommandProtocol,
                                        response: RemoteCommandResponseProtocol)
}

#endif
