//
//  TealiumRemoteCommands.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/31/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if remotecommands
import TealiumCore
#endif

/// Manages instances of TealiumRemoteCommand
public class TealiumRemoteCommands: NSObject {

    weak var queue: DispatchQueue?
    var commands = [TealiumRemoteCommand]()
    var isEnabled = false
    static var pendingResponses = [String: Bool]()

    /// Checks if a URLRequest object contains a valid Remote Command
    ///
    /// - Parameter request: URLRequest representing the Remote Command
    /// - Returns: Bool indicating whether the command is valid
    func isAValidRemoteCommand(request: URLRequest) -> Bool {
        if request.url?.scheme == TealiumKey.tealiumURLScheme {
            return true
        }

        return false
    }

    /// Adds a remote command for later execution
    ///
    /// - Parameters:
    /// - remoteCommand: TealiumRemoteCommand to be added for later execution
    public func add(_ remoteCommand: TealiumRemoteCommand) {
        // NOTE: Multiple commands with the same command id are possible - OK
        remoteCommand.delegate = self
        commands.append(remoteCommand)
    }

    /// Removes a Remote Command so it can no longer be called
    ///
    /// - Parameters:
    /// - commandId: String containing the command ID to be removed
    public func remove(commandWithId: String) {
        commands.removeCommandForId(commandWithId)
    }

    /// Enables the Remote Commands feature
    func enable() {
        isEnabled = true
    }

    /// Disables Remote Commands and removes all previously-added Remote Commands so they can no longer be executed
    func disable() {
        commands.removeAll()
        isEnabled = false
    }

    /// Trigger an associated remote command from a string representation of a url request. Function
    ///     will presume the string is escaped, if not, will attempt to escape string
    ///     with .urlQueryAllowed. NOTE: using .urlHostAllowed for escaping will not work.
    ///
    /// - Parameter urlString: Url string including host, ie: tealium://commandId?request={}...
    /// - Returns: Error if unable to trigger a remote command. Can ignore if the url was not
    ///     intended for a remote command.
    public func triggerCommandFrom(urlString: String) -> TealiumRemoteCommandsError? {
        var urlInitial = URL(string: urlString)
        if urlInitial == nil {
            guard let escapedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                return TealiumRemoteCommandsError.requestNotProperlyFormatted
            }
            urlInitial = URL(string: escapedString)
        }
        guard let url = urlInitial else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }
        let request = URLRequest(url: url)

        return triggerCommandFrom(request: request)
    }

    /// Trigger an associated remote command from a url request.
    ///
    /// - Parameter request: URLRequest to check for a remote command.
    /// - Returns: Error if unable to trigger a remote command. If nil is returned,
    ///     then call was a successfully triggered remote command.
    public func triggerCommandFrom(request: URLRequest) -> TealiumRemoteCommandsError? {

        if request.url?.scheme != TealiumKey.tealiumURLScheme {
            return TealiumRemoteCommandsError.invalidScheme
        }

        guard let commandId = request.url?.host else {
            return TealiumRemoteCommandsError.noCommandIdFound
        }

        guard let command = commands.commandForId(commandId) else {
            return TealiumRemoteCommandsError.noCommandForCommandIdFound
        }

        guard let response = TealiumRemoteCommandResponse(request: request) else {
            return TealiumRemoteCommandsError.requestNotProperlyFormatted
        }

        if isEnabled == false {
            // Was valid remote command, but we're disabled at the moment.
            return nil
        }

        if let responseId = response.responseId() {
         TealiumRemoteCommands.pendingResponses[responseId] = true
        }
        command.completeWith(response: response)

        return nil
    }
}

extension TealiumRemoteCommands: TealiumRemoteCommandDelegate {

    /// Triggers the completion block registered for a specific remote command
    ///
    /// - Parameters:
    /// - command: The Remote Command to be executed
    /// - response: The Response object passed back from TiQ. If the command needs to explictly handle the response (e.g. data needs passing back to webview),
    ///    it must set the "hasCustomCompletionHandler" flag, otherwise the completion notification will be sent automatically
    func tealiumRemoteCommandRequestsExecution(_ command: TealiumRemoteCommand,
                                               response: TealiumRemoteCommandResponse) {
        self.queue?.async {
            command.remoteCommandCompletion(response)
            // this will send the completion notification, if it wasn't explictly handled by the command
            if !response.hasCustomCompletionHandler {
             TealiumRemoteCommand.sendCompletionNotification(for: command.commandId, response: response)
            }
        }
    }
}
