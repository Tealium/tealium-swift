//
//  RemoteCommandsConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

#if remotecommands
import TealiumCore
#endif

/// This enum defines how the RemoteCommand is configured by the user.
///
/// The configuration will be used for mapping events data into vendor specific data.
public enum RemoteCommandType {
    /// A RemoteCommand that is configured via TiQ tag in the webview. The tag handles the mapping for this type.
    case webview
    /// A RemoteCommand that is configured via JSON file hosted remotely. The RemoteCommand module handles the mapping for this type using the JSON config.
    case remote(url: String)
    /// A RemoteCommand that is configured via JSON file bundled in the user app. The RemoteCommand module handles the mapping for this type using the JSON config.
    case local(file: String, bundle: Bundle? = nil)
}

public enum SimpleCommandType {
    case webview
    case JSON
}

enum RemoteCommandsKey {
    static let moduleName = "remotecommands"

    static let authenticate = "authenticate"
    static let headers = "headers"
    static let method = "method"
    static let parameters = "parameters"
    static let url = "url"
    static let body = "body"
    static let payload = "payload"
    static let config = "config"
    static let request = "request"
    static let username = "username"
    static let password = "password"
    static let responseId = "response_id"
    static let commandId = "_http"
    static let jsCommand = "js"
    static let commandName = "command_name"
    static let defaultRefreshInterval = 3600
    static let keysSeparationDelimiter = "keys_separation_delimiter"
    static let keysEqualityDelimiter = "keys_equality_delimiter"
    static let errorCooldownBaseInterval: Double = 30
}

enum RemoteCommandStatusCode: Int {
    case unknown = 0
    case success = 200
    case noContent = 204
    case malformed = 400
    case failure = 404
}

public enum TealiumRemoteCommandsError: TealiumErrorEnum, Equatable {
    case invalidScheme
    case commandIdNotFound
    case commandNotFound
    case remoteCommandsDisabled
    case requestNotProperlyFormatted
    case mappingsNotFound
    case commandsNotFound
    case commandNameNotFound
}

enum TealiumRemoteCommandResponseError: TealiumErrorEnum {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}

#endif
