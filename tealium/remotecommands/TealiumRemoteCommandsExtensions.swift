//
//  TealiumRemoteCommandsExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if remotecommands
import TealiumCore
#endif

public extension Tealium {
    /// Returns an instance of TealiumRemoteCommands to allow new commands to be registered.
    func remoteCommands() -> TealiumRemoteCommands? {
        guard let module = modulesManager.getModule(forName: TealiumRemoteCommandsKey.moduleName) as? TealiumRemoteCommandsModule else {
            return nil
        }

        return module.remoteCommands
    }
}

public extension TealiumConfig {

    /// Disables the built-in HTTP command
    func disableRemoteHTTPCommand() {
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = true
    }

    /// Re-enables the built-in HTTP command
    func enableRemoteHTTPCommand() {
        optionalData[TealiumRemoteCommandsKey.disableHTTP] = false
    }

    /// Registers a Remote Command for later execution

    /// - Parameter command: TealiumRemoteCommand instance
    func addRemoteCommand(_ command: TealiumRemoteCommand) {
        var commands = optionalData[TealiumRemoteCommandsKey.allCommands] as? [TealiumRemoteCommand] ?? [TealiumRemoteCommand]()
        commands.append(command)
        optionalData[TealiumRemoteCommandsKey.allCommands] = commands
    }

    /// Retrieves all currently-registered Remote Commands
    ///
    /// - Returns: [TealiumRemoteCommand]
    func getRemoteCommands() -> [TealiumRemoteCommand]? {
        return optionalData[TealiumRemoteCommandsKey.allCommands] as? [TealiumRemoteCommand]
    }
}

extension Array where Element: TealiumRemoteCommand {

    func commandForId(_ commandId: String) -> TealiumRemoteCommand? {
        return self.first(where: { $0.commandId == commandId })
    }

    mutating func removeCommandForId(_ commandId: String) {
        for (index, command) in self.reversed().enumerated() where command.commandId == commandId {
            self.remove(at: index)
        }
    }

}

public extension URL {

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

    func asDictionary() -> [String: Any] {
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

    mutating func assignHeadersFrom(dictionary: [String: Any]) {
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            guard let value = dictionary[key] as? String else {
                continue
            }
            self.addValue(value, forHTTPHeaderField: key)
        }
    }
}

extension URLQueryItem {

    var dictionaryRepresentation: [String: Any]? {
        if let value = value {
            return [name: value]
        }
        return nil
    }
}
