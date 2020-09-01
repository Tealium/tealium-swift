//
//  RemoteCommandsExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public extension Tealium {

    /// Returns an instance of TealiumRemoteCommands to allow new commands to be registered.
    var remoteCommands: RemoteCommandsManagerProtocol? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == RemoteCommandsModule.self
        } as? RemoteCommandsModule)?.remoteCommands
    }
}

public extension Dispatchers {
    static let RemoteCommands = RemoteCommandsModule.self
}

public extension TealiumConfig {

    /// Enables or disables the built-in HTTP command. Default `false` (command is ENABLED). Set to `true` to disable
    var remoteHTTPCommandDisabled: Bool {
        get {
            options[RemoteCommandsKey.disableHTTP] as? Bool ?? false
        }

        set {
            options[RemoteCommandsKey.disableHTTP] = newValue
        }
    }

    /// Registers a Remote Command for later execution
    ///
    /// - Parameter command: `TealiumRemoteCommandProtocol` instance
    func addRemoteCommand(_ command: RemoteCommandProtocol) {
        var commands = remoteCommands ?? RemoteCommandArray()
        commands.append(command)
        remoteCommands = commands
    }

    var remoteCommands: RemoteCommandArray? {
        get {
            options[RemoteCommandsKey.allCommands] as? RemoteCommandArray
        }

        set {
            options[RemoteCommandsKey.allCommands]  = newValue
        }
    }
}

extension Array where Element: RemoteCommand {

    /// Retrieves a command for a specific command ID
    ///
    /// - Parameter commandId: `String`
    /// - Returns: `TealiumRemoteCommand?`
    func commandForId(_ commandId: String) -> RemoteCommand? {
        return self.first(where: { $0.commandId == commandId })
    }

    /// Removes a command for a specific command ID
    ///
    /// - Parameter commandId: `String`
    mutating func removeCommandForId(_ commandId: String) {
        for (index, command) in self.reversed().enumerated() where command.commandId == commandId {
            self.remove(at: index)
        }
    }

}

public extension RemoteCommandArray {
    subscript(_ id: String) -> RemoteCommandProtocol? {
        return self.first {
            $0.commandId == id
        }
    }

    /// Removes a command by id from the RemoteCommandArray
    /// - Parameter id: Parameter id: `String`
    mutating func removeCommand(_ id: String) {
        var copy = self
        for (index, command) in copy.reversed().enumerated() where command.commandId == id {
            copy.remove(at: index)
        }
        self = copy
    }

}

extension URL {
    var queryItems: [String: Any] {
        var params = [String: Any]()
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce([:], { _, item -> [String: Any] in
                params[item.name] = item.value
                return params
            }) ?? [:]
    }
}

extension URLRequest {
    var dictionary: [String: Any] {
        var result = [String: Any]()
        result["allowsCellularAccess"] = self.allowsCellularAccess ? "true" : "false"
        result["allHTTPHeaderFields"] = self.allHTTPHeaderFields
        result["cachePolicy"] = self.cachePolicy
        result["url"] = self.url?.absoluteString
        result["timeoutInterval"] = self.timeoutInterval
        result["httpMethod"] = self.httpMethod
        result["httpShouldHandleCookies"] = self.httpShouldHandleCookies
        result["httpShouldUsePipelining"] = self.httpShouldUsePipelining
        return result
    }
    mutating func headersFrom(dictionary: [String: Any]) {
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            guard let value = dictionary[key] as? String else {
                continue
            }
            self.addValue(value, forHTTPHeaderField: key)
        }
    }
}
#endif
