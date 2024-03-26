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

public enum RemoteCommandType {
    case webview
    case remote(url: String)
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
    static let defaultRefreshInterval = Int(3600)
    static let keysSeparationDelimiter = "keys_separation_delimiter"
    static let keysEqualityDelimiter = "keys_equality_delimiter"
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
    case invalidFileName
    case couldNotConvertData
    case couldNotDecodeJSON
    case errorLoadingRemoteJSON
    case mappingsNotFound
    case commandsNotFound
    case commandNameNotFound
    case noResponse
    case invalidResponse
    case notModified
}

enum TealiumRemoteCommandResponseError: TealiumErrorEnum {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}

#endif
