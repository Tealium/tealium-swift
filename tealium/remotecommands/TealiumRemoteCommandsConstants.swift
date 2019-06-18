//
//  TealiumRemoteCommandsConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/6/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandsKey {
    static let moduleName = "remotecommands"
    static let disable = "disable_remote_commands"
    static let disableHTTP = "disable_remote_command_http"
    static let allCommands = "remote_commands"
}

enum TealiumRemoteCommandStatusCode: Int {
    case unknown = 0
    case success = 200
    case noContent = 204
    case malformed = 400
    case failure = 404
}

enum TealiumRemoteHTTPCommandKey {
    static let commandId = "_http"
    static let jsCommand = "js"
}

enum TealiumRemoteCommandsHTTPKey {
    static let authenticate = "authenticate"
    static let body = "body"
    static let headers = "headers"
    static let method = "method"
    static let parameters = "parameters"
    static let password = "password"
    static let responseId = "response_id"
    static let url = "url"
    static let username = "username"
}

enum TealiumRemoteCommandResponseError: Error {
    case noMappedPayloadData
    case missingURLTarget
    case missingURLMethod
    case couldNotConvertDataToURL
}
