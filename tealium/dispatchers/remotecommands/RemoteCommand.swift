//
//  RemoteCommand.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

/// Designed to be subclassed. Allows Remote Commands to be created by host apps,
/// and called on-demand by the Tag Management module
open class RemoteCommand: RemoteCommandProtocol {

    open var version: String? {
        versionForObject(self)
    }
    open var name: String {
        commandId
    }

    public let commandId: String
    weak public var delegate: RemoteCommandDelegate?
    public var description: String?
    public var config: RemoteCommandConfig?
    public var type: RemoteCommandType
    public var completion: (_ response: RemoteCommandResponseProtocol) -> Void

    /// Constructor for a Tealium Remote Command.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for command block.
    ///     - description: `String?` description of command.
    ///     - urlSession: `URLSessionProtocol`
    ///     - completion: The completion block to run when this remote command is triggered.
    public init(commandId: String,
                description: String?,
                type: RemoteCommandType = .webview,
                completion: @escaping (_ response: RemoteCommandResponseProtocol) -> Void) {

        self.commandId = commandId
        self.description = description
        self.type = type
        self.completion = completion
    }

    /// Called when a Remote Command is ready for execution.
    /// ￼
    /// - Parameter response: `RemoteCommandResponse` object containing information from the TiQ webview
    public func completeWith(response: RemoteCommandResponseProtocol) {
        TealiumQueues.backgroundSerialQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.remoteCommandRequestsExecution(self,
                                                          response: response)
        }
    }

    /// Called when the `TealiumJSONCommand` is ready for execution
    ///
    /// - Parameter trackData: The data recieved in the track call
    public func complete(with trackData: [String: Any], config: RemoteCommandConfig, completion: ModuleCompletion?) {
        if let payload = self.process(trackData: trackData, commandConfig: config, completion: completion) {
            let response = JSONRemoteCommandResponse(with: payload)
            delegate?.remoteCommandRequestsExecution(self,
                                                     response: response)
        }
    }

    /// Generates response data for a specific Remote Command.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for the Remote Command
    ///     - response: `RemoteCommandResponse` from the remote command to be passed back to the TiQ webview
    ///     - Returns: `[String: Any]?`  containing the encoded JavaScript string for the TiQ webview.
    class func remoteCommandResponse(for commandId: String,
                                     response: RemoteCommandResponse) -> [String: Any]? {
        guard let responseId = response.responseId else {
            return nil
        }
        var responseStr: String
        if let responseData = response.data, let responseString = String(data: responseData, encoding: .utf8) {
            responseStr = responseString
        } else {
            // keep previous behavior from obj-c library
            responseStr = "(null)"
        }
        let jsString = "try { utag.mobile.remote_api.response['\(commandId)']['\(responseId)']('\(String(describing: response.status))','\(responseStr)')} catch(err) {console.error(err)}"
        return [RemoteCommandsKey.jsCommand: jsString]
    }

    /// Sends Remote Command response data to the TiQ webview when
    /// the remote command has finished executing.
    ///
    /// - Parameters:
    ///     - commandId: `String` identifier for the Remote Command
    ///     - response: `RemoteCommandResponse` from the remote command to be passed back to the TiQ webview
    ///     - delegate: `TealiumModuleDelegate?`
    public class func sendRemoteCommandResponse(for commandId: String,
                                                response: RemoteCommandResponseProtocol,
                                                delegate: ModuleDelegate?) {
        guard let tealiumResponse = response as? RemoteCommandResponse,
              let responseId = tealiumResponse.responseId,
              RemoteCommandsManager.pendingResponses.value[responseId] == true else {
            return
        }
        RemoteCommandsManager.pendingResponses.value[responseId] = nil
        guard let response = remoteCommandResponse(for: commandId,
                                                   response: tealiumResponse) else {
            return
        }
        let request = TealiumRemoteCommandRequestResponse(data: response)
        delegate?.processRemoteCommandRequest(request)
    }

    public func process(trackData: [String: Any], commandConfig: RemoteCommandConfig, completion: ModuleCompletion?) -> [String: Any]? {
        JSONRemoteCommandPayloadBuilder.process(trackData: trackData,
                                                commandConfig: commandConfig,
                                                completion: completion)
    }
}
#endif
