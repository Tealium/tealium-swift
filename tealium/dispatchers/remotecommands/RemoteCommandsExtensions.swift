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
        var commands = remoteCommands ?? [RemoteCommandProtocol]()
        commands.append(command)
        remoteCommands = commands
    }

    var remoteCommands: [RemoteCommandProtocol]? {
        get {
            options[RemoteCommandsKey.allCommands] as? [RemoteCommandProtocol]
        }

        set {
            options[RemoteCommandsKey.allCommands]  = newValue
        }
    }

    /// Sets the refresh interval for which to fetch the JSON remote command config
    /// - Returns: `TealiumRefreshInterval` default is `.every(1, .hours)`
    var remoteCommandConfigRefresh: TealiumRefreshInterval {
        get {
            return options[RemoteCommandsKey.refreshInterval] as? TealiumRefreshInterval ?? .every(1, .hours)
        }
        set {
            options[RemoteCommandsKey.refreshInterval] = newValue
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

    /// URL initializer does not actually validate web addresses successfully (it's too permissive), so this additional check is required￼.
    ///
    /// - Returns: `Bool` `true` if URL is a valid web address
    var isValidUrl: Bool {
        let urlRegexPattern = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        guard let validURLRegex = try? NSRegularExpression(pattern: urlRegexPattern, options: []) else {
            return false
        }
        return validURLRegex.rangeOfFirstMatch(in: self, options: [], range: NSRange(self.startIndex..., in: self)).location != NSNotFound
    }

    /// Adds the key _cb= to the end of the url with a random number to clear the cached file from the CDN
    var cacheBuster: String {
        return ("\(self)?_cb=\(Int.random(in: 1...10_000))")
    }

    var fileName: String {
        guard let jsonFile = self.components(separatedBy: "/").last,
              jsonFile.contains(".json") else {
            return ""
        }
        return jsonFile.components(separatedBy: ".json")[0]
    }

}
#endif
