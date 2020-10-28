//
//  RemoteCommandResponse.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public class RemoteCommandResponse: RemoteCommandResponseProtocol, CustomStringConvertible {

    public var status: Int? = RemoteCommandStatusCode.noContent.rawValue
    public var urlRequest: URLRequest?
    public var urlResponse: URLResponse?
    public var data: Data?
    public var error: Error?
    public var payload: [String: Any]?
    public var hasCustomCompletionHandler = false

    public var description: String {
        return """
        <RemoteCommandResponse: config:\(config),
        status:\(String(describing: status)),
        payload:\(String(describing: payload)),
        response: \(String(describing: urlResponse)),
        data:\(String(describing: data))
        error:\(String(describing: error))>
        """
    }

    /// Allows initialization from a String representing a valid URL
    ///￼
    /// - Parameter urlString: `String` representing a valid URL with which to initialize a RemoteCommandResponse
    public convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        let urlRequest = URLRequest(url: url)
        self.init(request: urlRequest)
    }

    /// Constructor for a Tealium Remote Command. Fails if the request was not
    /// formatted correctly for remote command use.
    ///￼
    /// - Parameter request: `URLRequest` object with which to initialize a RemoteCommandResponse
    public init?(request: URLRequest) {
        self.urlRequest = request
        guard let requestData = requestData(from: request),
              let _ = configData(from: requestData),
              let payload = payload(from: requestData) else {
            return nil
        }
        self.payload = payload
    }

    /// Extracts variables from a URLRequest and returns a dictionary
    ///￼
    /// - Parameter request: `URLRequest` containing valid data with which to form a RemoteCommandResponse
    /// - Returns: `[String: Any]?` containing key-value pairs to add to the RemoteCommandResponse
    func requestData(from request: URLRequest) -> [String: Any]? {
        guard let parameters = parameters(from: request),
              let requestString = parameters[RemoteCommandsKey.request] as? String,
              let dictionary = dictionary(from: requestString) else {
            return nil
        }
        return dictionary
    }

    /// Extracts the config data from requestData.
    /// Config usually contains response_id, used to call back to the WebView/Tag Management module.
    ///￼
    /// - Parameter requestData: `[String: Any]` representation of a Remote Command response coming from the WebView/Tag Management module
    /// - Returns: `[String: Any]?` containing config data for this Remote Command
    public func configData(from requestData: [String: Any]) -> [String: Any]? {
        guard let config = requestData[RemoteCommandsKey.config] as? [String: Any] else {
            return nil
        }
        return config
    }

    /// Extracts the payload data from requestData.
    /// Payload usually contains custom data passed back from the WebView/Tag Management module.
    ///￼
    /// - Parameter requestData: `[String: Any]` representation of a Remote Command response coming from the WebView/Tag Management module
    /// - Returns: `[String: Any]?` containing payload data for this Remote Command
    public func payload(from requestData: [String: Any]) -> [String: Any]? {
        guard let payload = requestData[RemoteCommandsKey.payload] as? [String: Any] else {
            return nil
        }
        return payload
    }

    /// Gets the config dictionary from an already-instantiated Remote Command
    ///
    /// - Returns: `[String: Any] `containing the config for this Remote Command
    public var config: [String: Any] {
        guard let request = self.urlRequest,
              let requestData = requestData(from: request),
              let config = configData(from: requestData) else {
            return [String: Any]()
        }
        return config
    }

    /// Gets the Response ID from the original remote command invocation.
    /// This is used to call back to the WebView/Tag Management module
    ///
    /// - Returns: `String?` containing the Response ID
    public var responseId: String? {
        guard let responseId = config[RemoteCommandsKey.responseId] as? String else {
            return nil
        }
        return responseId
    }

    /// Converts a JSON string into a dictionary
    ///￼
    /// - Parameter string: `String` representing a JSON object
    /// - Returns: `[String: Any]?`
    func dictionary(from string: String) -> [String: Any]? {
        guard let data = string.data(using: .utf8), let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return dictionary
    }

    /// Gets the query parameters from a URLRequest
    ///￼
    /// - Parameter request: `URLRequest`
    /// - Returns: `[String: Any]?` containing query parameters, if present.
    func parameters(from request: URLRequest) -> [String: Any]? {
        request.url?.queryItems
    }
}
#endif
