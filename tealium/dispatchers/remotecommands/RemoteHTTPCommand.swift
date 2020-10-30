//
//  RemoteHTTPCommand.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if remotecommands
import TealiumCore
#endif

public class RemoteHTTPCommand: RemoteCommand {

    /// - Returns:`RemoteHTTPCommand`
    public class func create(with delegate: ModuleDelegate?) -> RemoteCommandProtocol {
        return RemoteCommand(commandId: RemoteCommandsKey.commandId,
                             description: "For processing tag-triggered HTTP requests") { response in
            guard let response = response as? RemoteCommandResponse else {
                return
            }
            response.hasCustomCompletionHandler = true
            let requestInfo = RemoteHTTPCommand.httpRequest(from: response.payload ?? [:])
            guard let request = requestInfo.request else {
                return
            }
            RemoteCommand.urlSession.tealiumDataTask(with: request,
                                                     completionHandler: { data, urlResponse, error in
                                                        if let error = error {
                                                            response.error = error
                                                            response.status = RemoteCommandStatusCode.failure.rawValue
                                                        } else {
                                                            response.status = RemoteCommandStatusCode.success.rawValue
                                                        }
                                                        if data == nil {
                                                            response.status = RemoteCommandStatusCode.noContent.rawValue
                                                        }
                                                        if urlResponse == nil {
                                                            response.status = RemoteCommandStatusCode.failure.rawValue
                                                        }
                                                        response.urlResponse = urlResponse
                                                        response.data = data
                                                        RemoteCommand.sendRemoteCommandResponse(for: RemoteCommandsKey.commandId,
                                                                                                response: response,
                                                                                                delegate: delegate)
                                                     }).resume()
        }
    }

    /// Forms a URLRequest from a dictionary payload containing predetermined config keys
    ///￼
    /// - Parameter payload: [String: Any] payload representing a set of key-value pairs to be sent with the URLRequest
    /// - Returns: `(URLRequest?, Error?)`
    public class func httpRequest(from payload: [String: Any]) -> (request: URLRequest?, error: Error?) {
        guard let urlStringValue = payload[RemoteCommandsKey.url] as? String else {
            return (nil, TealiumRemoteCommandResponseError.missingURLTarget)
        }
        guard let method = payload[RemoteCommandsKey.method] as? String else {
            return (nil, TealiumRemoteCommandResponseError.missingURLMethod)
        }
        var urlComponents = URLComponents(string: urlStringValue)
        if let paramsData = payload[RemoteCommandsKey.parameters] as? [String: Any] {
            urlComponents?.queryItems = RemoteHTTPCommand.queryItems(from: paramsData)
        }
        guard let url = urlComponents?.url else {
            return (nil, TealiumRemoteCommandResponseError.couldNotConvertDataToURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let headersData = payload[RemoteCommandsKey.headers] as? [String: Any] {
            request.headersFrom(dictionary: headersData)
        }
        if let body = payload[RemoteCommandsKey.body] as? String {
            request.httpBody = body.data(using: .utf8)
            request.addValue("\([UInt8](body.utf8))", forHTTPHeaderField: "Content-Length")
        }
        if let body = payload[RemoteCommandsKey.body] as? [String: Any] {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        if let authenticationData = payload[RemoteCommandsKey.authenticate] as? [String: Any] {
            if let username = authenticationData[RemoteCommandsKey.username] as? String,
               let password = authenticationData[RemoteCommandsKey.password] as? String {
                if let loginData = "\(username):\(password)".data(using: .utf8) {
                    let base64LoginString = loginData.base64EncodedString()
                    request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
                }
            }
        }
        return (request, nil)
    }

    /// Returns sorted queryItems from a dictionary.
    ///￼
    /// - Parameter dictionary: `[String:Any]`
    /// - Returns: Sorted `[URLQueryItem]` array by dictionary keys
    public class func queryItems(from dictionary: [String: Any]) -> [URLQueryItem] {
        var queryItems = [URLQueryItem]()
        dictionary.keys.sorted().forEach {
            let value = String(describing: dictionary[$0]!)
            let queryItem = URLQueryItem(name: $0, value: value)
            queryItems.append(queryItem)
        }
        return queryItems
    }

}
#endif
