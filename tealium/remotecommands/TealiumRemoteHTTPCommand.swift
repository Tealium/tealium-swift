//
//  TealiumRemoteHTTPCommand.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/4/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if remotecommands
import TealiumCore
#endif

class TealiumRemoteHTTPCommand: TealiumRemoteCommand {

    /// Returns an instance of the TealiumRemoteHTTPCommand
    class func httpCommand() -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: TealiumRemoteHTTPCommandKey.commandId,
                                    description: "For processing tag-triggered HTTP requests") { response in
                                        response.hasCustomCompletionHandler = true
                                        let requestInfo = TealiumRemoteHTTPCommand.httpRequest(payload: response.payload())

                                        guard let request = requestInfo.request else {
                                            return
                                        }

                                        let task = URLSession.shared.dataTask(with: request,
                                                                              completionHandler: { data, urlResponse, error in
                                                                                // Legacy status reporting
                                                                                if let err = error {
                                                                                    response.error = err
                                                                                    response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                                                                                } else {
                                                                                    response.status = TealiumRemoteCommandStatusCode.success.rawValue
                                                                                }
                                                                                if data == nil {
                                                                                    response.status = TealiumRemoteCommandStatusCode.noContent.rawValue
                                                                                }
                                                                                if urlResponse == nil {
                                                                                    response.status = TealiumRemoteCommandStatusCode.failure.rawValue
                                                                                }
                                                                                response.urlResponse = urlResponse
                                                                                response.data = data
                                                                                TealiumRemoteHTTPCommand.sendCompletionNotification(for: TealiumRemoteHTTPCommandKey.commandId,
                                                                                                                                    response: response)
                                        })

                                        task.resume()
        }
    }

    /// Forms a URLRequest from a dictionary payload containing predetermined config keys
    ///
    /// - Parameter payload: [String: Any] payload representing a set of key-value pairs to be sent with the URLRequest
    /// - Returns: A tuple containing an optional URLRequest object and an optional Error object
    class func httpRequest(payload: [String: Any]) -> (request: URLRequest?, error: Error?) {
        guard let urlStringValue = payload[TealiumRemoteCommandsHTTPKey.url] as? String else {
            // This response is not intended for use as an HTTP command
            return (nil, TealiumRemoteCommandResponseError.missingURLTarget)
        }

        guard let method = payload[TealiumRemoteCommandsHTTPKey.method] as? String else {
            // No idea what sort of URL call we should be making
            return (nil, TealiumRemoteCommandResponseError.missingURLMethod)
        }

        var urlComponents = URLComponents(string: urlStringValue)

        if let paramsData = payload[TealiumRemoteCommandsHTTPKey.parameters] as? [String: Any] {
            let paramQueryItems = TealiumRemoteHTTPCommand.paramItemsFrom(dictionary: paramsData)
            urlComponents?.queryItems = paramQueryItems
        }

        guard let url = urlComponents?.url else {
            return (nil, TealiumRemoteCommandResponseError.couldNotConvertDataToURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        if let headersData = payload[TealiumRemoteCommandsHTTPKey.headers] as? [String: Any] {
            request.assignHeadersFrom(dictionary: headersData)
        }
        if let body = payload["body"] as? String {
            request.httpBody = body.data(using: .utf8)
            request.addValue("\([UInt8](body.utf8))", forHTTPHeaderField: "Content-Length")
        }
        if let body = payload["body"] as? [String: Any] {
            let jsonData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        if let authenticationData = payload[TealiumRemoteCommandsHTTPKey.authenticate] as? [String: Any] {
            if let username = authenticationData["username"] as? String,
                let password = authenticationData["password"] as? String {

                let loginString = "\(username):\(password)"
                let loginData = loginString.data(using: String.Encoding.utf8)!
                let base64LoginString = loginData.base64EncodedString()
                request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

            }
        }

        return (request, nil)
    }

    /// Returns sorted queryItems from a dictionary.
    ///
    /// - Parameter dictionary: Dictionary of type [String:Any]
    /// - Returns: Sorted [URLQueryItem] array by dictionary keys
    class func paramItemsFrom(dictionary: [String: Any]) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        let sortedKeys = Array(dictionary.keys).sorted(by: <)
        for key in sortedKeys {
            // Convert all values to string
            let value = String(describing: dictionary[key]!)
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        return queryItems
    }

    override func completeWith(response: TealiumRemoteCommandResponse) {
        self.remoteCommandCompletion(response)
    }

}
