//
//  TealiumRemoteCommandResponse.swift
//  tealium-swift
//
//  Created by Craig Rouse on 06/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if remotecommands
import TealiumCore
#endif

public class TealiumRemoteCommandResponse: CustomStringConvertible {

    public var status: Int = TealiumRemoteCommandStatusCode.noContent.rawValue
    public var urlRequest: URLRequest
    public var urlResponse: URLResponse?
    public var data: Data?
    public var error: Error?
    public var hasCustomCompletionHandler = false

    public var description: String {
        return """
        <TealiumRemoteCommandResponse: config:\(config()),
                                       status:\(status),
                                       payload:\(payload()),
                                       response: \(String(describing: urlResponse)),
                                       data:\(String(describing: data))
                                       error:\(String(describing: error))>
        """
    }

    /// Allows initialization from a String representing a valid URL
    ///￼
    /// - Parameter urlString: `String` representing a valid URL with which to initialize a RemoteCommandResponse
    convenience init?(urlString: String) {
        // Convert string to url request then process as usual
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
    init?(request: URLRequest) {
        self.urlRequest = request

        guard let requestData = requestDataFrom(request: request) else {
            return nil
        }
        guard configFrom(requestData: requestData) != nil else {
            return nil
        }
        guard payloadFrom(requestData: requestData) != nil else {
            return nil
        }
    }

    /// Extracts variables from a URLRequest and returns a dictionary
    ///￼
    /// - Parameter request: `URLRequest` containing valid data with which to form a RemoteCommandResponse
    /// - Returns: `[String: Any]?` containing key-value pairs to add to the RemoteCommandResponse
    func requestDataFrom(request: URLRequest) -> [String: Any]? {
        guard let paramData = TealiumRemoteCommandResponse.paramDataFrom(request) else {
            return nil
        }
        guard let requestDataString = paramData["request"] as? String else {
            return nil
        }
        guard let requestData = TealiumRemoteCommandResponse.convertToDictionary(text: requestDataString) else {
            return nil
        }
        return requestData
    }

    /// Extracts the config data from requestData.
    /// Config usually contains response_id, used to call back to the WebView/Tag Management module.
    ///￼
    /// - Parameter requestData: `[String: Any]` representation of a Remote Command response coming from the WebView/Tag Management module
    /// - Returns: `[String: Any]?` containing config data for this Remote Command
    public func configFrom(requestData: [String: Any]) -> [String: Any]? {
        guard let config = requestData["config"] as? [String: Any] else {
            return nil
        }
        return config
    }

    /// Extracts the payload data from requestData.
    /// Payload usually contains custom data passed back from the WebView/Tag Management module.
    ///￼
    /// - Parameter requestData: `[String: Any]` representation of a Remote Command response coming from the WebView/Tag Management module
    /// - Returns: `[String: Any]?` containing payload data for this Remote Command
    public func payloadFrom(requestData: [String: Any]) -> [String: Any]? {
        guard let payload = requestData["payload"] as? [String: Any] else {
            return nil
        }
        return payload
    }

    /// Gets the config dictionary from an already-instantiated Remote Command
    ///
    /// - Returns: `[String: Any] `containing the config for this Remote Command
    public func config() -> [String: Any] {
        guard let requestData = requestDataFrom(request: self.urlRequest), let config = configFrom(requestData: requestData) else {
            // Return an empty dictionary in case of failure. Should not get here, as the initializer would have failed earlier on.
            return [String: Any]()
        }
        return config
    }

    /// Gets the payload dictionary from an already-instantiated Remote Command
    ///
    /// - Returns: `[String: Any]` containing the payload for this Remote Command
    public func payload() -> [String: Any] {
        guard let requestData = requestDataFrom(request: self.urlRequest), let payload = payloadFrom(requestData: requestData) else {
            // Return an empty dictionary in case of failure. Should not get here, as the initializer would have failed earlier on.
            return [String: Any]()
        }
        return payload
    }

    /// Converts a JSON string into a dictionary
    ///￼
    /// - Parameter text: `String` representing a JSON object
    /// - Returns: `[String: Any]?`
    class func convertToDictionary(text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            return nil
        }
    }

    /// Gets the query parameters from a URLRequest
    ///￼
    /// - Parameter request: `URLRequest`
    /// - Returns: `[String: Any]?` containing query parameters, if present.
    class func paramDataFrom(_ request: URLRequest) -> [String: Any]? {
        guard let url = request.url else {
            return nil
        }

        return url.queryItems
    }
}

public extension TealiumRemoteCommandResponse {

    /// Gets the Response ID from the original remote command invocation.
    /// This is used to call back to the WebView/Tag Management module
    ///
    /// - Returns: `String?` containing the Response ID
    func responseId() -> String? {
        guard let responseId = config()["response_id"] as? String else {
            return nil
        }
        return responseId
    }

    /// Gets the body field for an HTTP Remote Command
    ///
    /// - Returns: `String?` containing the body field for the Remote Command
    func body() -> String? {
        if let body = payload()["body"] as? String {
            return body
        }
        return nil
    }
}
