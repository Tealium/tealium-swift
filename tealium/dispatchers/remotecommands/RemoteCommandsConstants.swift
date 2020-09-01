//
//  RemoteCommandsConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/6/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation

enum RemoteCommandsKey {
    static let moduleName = "remotecommands"
    static let disable = "disable_remote_commands"
    static let disableHTTP = "disable_remote_command_http"
    static let allCommands = "remote_commands"
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
}

enum RemoteCommandStatusCode: Int {
    case unknown = 0
    case success = 200
    case noContent = 204
    case malformed = 400
    case failure = 404
}

public enum TealiumRemoteCommandsError: Error {
    case invalidScheme
    case noCommandIdFound
    case noCommandForCommandIdFound
    case remoteCommandsDisabled
    case requestNotProperlyFormatted
}

enum TealiumRemoteCommandResponseError: Error {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}
#endif
