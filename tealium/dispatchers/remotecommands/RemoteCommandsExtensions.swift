//
//  RemoteCommandsExtensions.swift
//  tealium-swift
//
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

extension TealiumDataKey {
    static let remoteCommands = "remote_commands"
}
extension TealiumConfigKey {
    static let disable = "disable_remote_commands"
    static let disableHTTP = "disable_remote_command_http"
    static let allCommands = "remote_commands"
    static let refreshInterval = "remote_config_refresh"
    static let remoteCommandsRemoteConfigBundle = "remote_command_remote_config_bundle"
}

public extension TealiumConfig {

    /// Enables or disables the built-in HTTP command. Default `false` (command is ENABLED). Set to `true` to disable
    var remoteHTTPCommandDisabled: Bool {
        get {
            options[TealiumConfigKey.disableHTTP] as? Bool ?? false
        }

        set {
            options[TealiumConfigKey.disableHTTP] = newValue
        }
    }

    /// Registers a Remote Command for later execution
    ///
    /// - Parameter command: `TealiumRemoteCommandProtocol` instance
    func addRemoteCommand(_ command: RemoteCommandProtocol) {
        var commands = remoteCommands ?? [RemoteCommandProtocol]()
        commands.append(command)
        remoteCommands = commands
    }

    var remoteCommands: [RemoteCommandProtocol]? {
        get {
            options[TealiumConfigKey.allCommands] as? [RemoteCommandProtocol]
        }

        set {
            options[TealiumConfigKey.allCommands] = newValue
        }
    }

    /// Sets the refresh interval for which to fetch the JSON remote command config
    /// - Returns: `TealiumRefreshInterval` default is `.every(1, .hours)`
    var remoteCommandConfigRefresh: TealiumRefreshInterval {
        get {
            return options[TealiumConfigKey.refreshInterval] as? TealiumRefreshInterval ?? .every(1, .hours)
        }
        set {
            options[TealiumConfigKey.refreshInterval] = newValue
        }
    }

    internal var remoteCommandsRemoteConfigBundle: Bundle {
        get {
            return options[TealiumConfigKey.remoteCommandsRemoteConfigBundle] as? Bundle ?? .main
        }
        set {
            options[TealiumConfigKey.remoteCommandsRemoteConfigBundle] = newValue
        }
    }

}

public extension Array where Element == RemoteCommandProtocol {
    subscript(_ id: String) -> RemoteCommandProtocol? {
        return self.first {
            $0.commandId == id
        }
    }
    /// Removes a command by id from the RemoteCommandArray
    /// - Parameter id: Parameter id: `String`
    mutating func removeCommand(_ id: String) {
        self = self.filter { $0.commandId != id }
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

public extension String {

    /// Adds the key _cb= to the end of the url with a random number to clear the cached file from the CDN
    var cacheBuster: String {
        return ("\(self)?_cb=\(Int.random(in: 1...10_000))")
    }
}
#endif
