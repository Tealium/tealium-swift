//
//  TealiumRemoteCommands.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/31/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumRemoteCommands: NSObject {

    weak var queue: DispatchQueue?
    var commands = [TealiumRemoteCommand]()
    var isEnabled = false
    var schemeProtocol = "tealium"

    func isAValidRemoteCommand(request: URLRequest) -> Bool {
        if request.url?.scheme == self.schemeProtocol {
            return true
        }

        return false
    }

    public func add(_ remoteCommand: TealiumRemoteCommand) {
        // NOTE: Multiple commands with the same command id are possible - OK
        remoteCommand.delegate = self
        commands.append(remoteCommand)
    }

    public func remove(commandWithId: String) {
        commands.removeCommandForId(commandWithId)
    }

    func enable() {
        isEnabled = true
    }

    // NOTE: Will wipe out all existing commands. Will need to re-add after.
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

        if request.url?.scheme != self.schemeProtocol {
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
        command.completeWith(response: response)

        return nil
    }

}

extension TealiumRemoteCommands: TealiumRemoteCommandDelegate {

    func tealiumRemoteCommandRequestsExecution(_ command: TealiumRemoteCommand,
                                               response: TealiumRemoteCommandResponse) {
        self.queue?.async {
            command.remoteCommandCompletion(response)
        }
    }

}
