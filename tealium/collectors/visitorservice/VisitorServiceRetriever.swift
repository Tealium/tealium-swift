//
//  VisitorServiceRetriever.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public class VisitorServiceRetriever {

    let urlSession: URLSessionProtocol
    var tealiumConfig: TealiumConfig

    enum URLRequestResult {
        case success(Data)
        case failure(NetworkError)
    }

    enum FetchVisitorProfileResult {
        case success(TealiumVisitorProfile?)
        case failure(NetworkError)
    }

    /// Creates a retriever instance for the visitor service
    ///
    /// - Parameters:
    ///   - config: existing TealiumConfig instance
    ///   - urlSession: shared URLSession
    init(config: TealiumConfig,
         urlSession: URLSessionProtocol = getURLSession()) {
        tealiumConfig = config
        self.urlSession = urlSession
    }

    /// - Returns: `URLSession` - `ephemeral` session to avoid sending cookies to UDH.
    /// If default session were used, previously-set TAPID cookies may be transmitted, which would override the default visitor ID
    class func getURLSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        return URLSession(configuration: config)
    }

    /// Sends a URLRequest, then calls the completion handler, passing success/failures back to the completion handler
    ///
    /// - Parameters:
    ///     - request: `URLRequest` object
    ///     - completion: Optional completion block to handle success/failure
    func sendURLRequest(_ request: URLRequest,
                        _ completion: @escaping (URLRequestResult) -> Void) {
        urlSession.tealiumDataTask(with: request) { data, response, error in
            TealiumQueues.backgroundSerialQueue.async {
                guard error == nil else {
                    if let error = error as? URLError, error.code == URLError.notConnectedToInternet || error.code == URLError.networkConnectionLost || error.code == URLError.timedOut {
                        completion(.failure(.noInternet))
                    } else {
                        completion(.failure(.unknownIssueWithSend))
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    completion(.failure(.unknownResponseType))
                    return
                }
                guard response.allHeaderFields[TealiumKey.errorHeaderKey] as? String == nil else {
                    completion(.failure(.xErrorDetected))
                    return
                }
                guard (200..<300).contains(response.statusCode) else {
                    completion(.failure(.non200Response))
                    return
                }
                guard let data = data else {
                    completion(.failure(.noDataToTrack))
                    return
                }
                completion(.success(data))
            }
        }.resume()
    }

    /// Generates the visitor service url
    func visitorServiceURL(tealiumVisitorId: String) -> String {
        var url = VisitorServiceConstants.defaultVisitorServiceDomain
        if let overrideURL = tealiumConfig.visitorServiceOverrideURL, URL(string: overrideURL) != nil {
            url = overrideURL
        }
        return "\(url)\(tealiumConfig.account)/\(tealiumConfig.visitorServiceOverrideProfile ?? tealiumConfig.profile)/\(tealiumVisitorId)"
    }

    /// Fetches the visitor profile from the visitor service endpoint
    ///
    /// - Parameter visitorId: visitor Id for the visitor
    /// - Parameter completion: Accepts a boolean to indicate if successful along with the updated profile retrieved
    func fetchVisitorProfile(visitorId: String, completion: @escaping (FetchVisitorProfileResult) -> Void) {
        guard let url = URL(string: visitorServiceURL(tealiumVisitorId: visitorId)) else {
            completion(.success(nil))
            return
        }
        let request = URLRequest(url: url)
        sendURLRequest(request) { result in
            switch result {
            case .success(let data):
                if let visitor = try? Tealium.jsonDecoder.decode(TealiumVisitorProfile.self, from: data) {
                    completion(.success(visitor))
                } else {
                    completion(.failure(.noDataToTrack))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    deinit {
        urlSession.finishTealiumTasksAndInvalidate()
    }

}
