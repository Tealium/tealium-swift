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

    public let commandId: String
    weak public var delegate: RemoteCommandDelegate?
    public var description: String?
    public var config: RemoteCommandConfig?
    public var type: RemoteCommandType
    static var urlSession: URLSessionProtocol = URLSession.shared
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
                completion : @escaping (_ response: RemoteCommandResponseProtocol) -> Void) {

        self.commandId = commandId
        self.description = description
        self.type = type
        self.completion = completion
    }

    /// Called when a Remote Command is ready for execution.
    ///￼
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
            delegate?.remoteCommandRequestsExecution(self, response: response)
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
        if let responseData = response.data {
            responseStr = String(data: responseData, encoding: .utf8)!
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
        guard let tealiumResponse = response as? RemoteCommandResponse else {
            return
        }
        guard let responseId = tealiumResponse.responseId else {
            return
        }
        guard RemoteCommandsManager.pendingResponses.value[responseId] == true else {
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

    /// Maps the track call data to the mappings and command names provided in the JSON file
    ///
    /// - Parameters:
    ///   - trackData: `[String: Any]` payload sent in the the track call
    ///   - commandConfig: `RemoteCommandConfig`decoded data loaded from the file name/url provided during initialization of the JSON command
    ///   - Returns: `[String: Any]` vendor specific data
    public func process(trackData: [String: Any], commandConfig: RemoteCommandConfig, completion: ModuleCompletion?) -> [String: Any]? {
        guard let mappings = commandConfig.mappings else {
            completion?((.failure(TealiumRemoteCommandsError.mappingsNotFound), nil))
            return nil
        }
        var mapped = objectMap(payload: trackData, lookup: mappings)
        guard let commandNames = commandConfig.apiCommands else {
            completion?((.failure(TealiumRemoteCommandsError.commandsNotFound), nil))
            return nil
        }
        guard let tealiumEvent = trackData[TealiumKey.event] as? String,
              let commandName = commandNames[tealiumEvent] else {
            completion?((.failure(TealiumRemoteCommandsError.commandNameNotFound), nil))
            return nil
        }
        mapped[RemoteCommandsKey.commandName] = commandName
        if let config = commandConfig.apiConfig {
            mapped.merge(config) { _, second in second }
        }
        return mapped
    }

    /// Maps the payload recieved from a tracking call to the data specific to the third party
    /// vendor specified for the remote command. A lookup dictionary is used to determine the
    /// mapping.
    /// - Parameter payload: `[String: Any]` from tracking call
    /// - Parameter self: `[String: String]` `mappings` key from JSON file definition
    /// - Returns: `[String: Any]` mapped key value pairs for specific remote command vendor
    public func mapPayload(_ payload: [String: Any], lookup: [String: String]) -> [String: Any] {
        return lookup.reduce(into: [String: Any]()) { result, dictionary in
            let values = dictionary.value.split(separator: ",")
            values.forEach {
                if payload[dictionary.key] != nil {
                    result[String($0)] = payload[dictionary.key]
                }
            }
        }
    }

    /// Performs mapping then splits any keys with a `.` present and creates a nested object
    /// from those keys using the `parseKeys()` method. If no keys with `.` are present,
    ///  performs mapping as normal using the `mapPayload()` method.
    /// - Parameter payload: `[String: Any]` from track method
    /// - Returns: `[String: Any]` mapped key value pairs for specific remote command vendor
    public func objectMap(payload: [String: Any], lookup: [String: String]) -> [String: Any] {
        let nestedMapped = mapPayload(payload, lookup: lookup)
        if nestedMapped.keys.filter({ $0.contains(".") }).count > 0 {
            var output = nestedMapped.filter({ !$0.key.contains(".") })
            let keysToParse = nestedMapped.filter { $0.key.contains(".") }
            _ = output += parseKeys(from: keysToParse)
            return output
        }
        return nestedMapped
    }

    /// Splits any keys with a `.` present and creates a nested object from those keys.
    /// e.g. if the key in the JSON was `event.parameter`, an object would be created
    /// like so: ["event": "parameter": "valueFromTrack"].
    /// - Returns: `[String: [String: Any]]` containing the new nested objects
    func parseKeys(from payload: [String: Any]) -> [String: [String: Any]] {
        payload.reduce(into: [String: [String: Any]]()) { result, dictionary in
            let key = String(dictionary.key.split(separator: ".")[0])
            let value = String(dictionary.key.split(separator: ".")[1])
            if result[key] == nil {
                result[key] = [value: dictionary.value]
            } else {
                result[key]! += [value: dictionary.value]
            }
        }
    }

}
#endif
