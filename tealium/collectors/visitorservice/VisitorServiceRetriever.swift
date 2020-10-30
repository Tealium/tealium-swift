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

    var urlSession: URLSessionProtocol?
    var tealiumConfig: TealiumConfig
    var visitorProfile: TealiumVisitorProfile?
    var lastFetch: Date?
    var tealiumVisitorId: String

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
    ///   - visitorId: visitor Id for the visitor
    ///   - urlSession: shared URLSession
    init(config: TealiumConfig,
         visitorId: String,
         urlSession: URLSessionProtocol = getURLSession()) {
        tealiumConfig = config
        self.urlSession = urlSession
        self.tealiumVisitorId = visitorId
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
        guard let urlSession = urlSession else {
            completion(.failure(.couldNotCreateSession))
            return
        }

        urlSession.tealiumDataTask(with: request) { data, response, error in
            guard error == nil else {
                if let error = error as? URLError, error.code == URLError.notConnectedToInternet || error.code == URLError.networkConnectionLost || error.code == URLError.timedOut {
                    completion(.failure(.noInternet))
                } else {
                    completion(.failure(.unknownIssueWithSend))
                }
                return
            }
            if let status = response as? HTTPURLResponse {
                if let _ = status.allHeaderFields[TealiumKey.errorHeaderKey] as? String {
                    completion(.failure(.xErrorDetected))
                } else if status.statusCode != 200 {
                    completion(.failure(.non200Response))
                } else if let data = data {
                    completion(.success(data))
                }
            }
        }.resume()
    }

    /// Generates the visitor service url
    var visitorServiceURL: String {
        var url = VisitorServiceConstants.defaultVisitorServiceDomain
        if let overrideURL = tealiumConfig.visitorServiceOverrideURL, URL(string: overrideURL) != nil {
            url = overrideURL
        }
        return "\(url)\(tealiumConfig.account)/\(tealiumConfig.visitorServiceOverrideProfile ?? tealiumConfig.profile)/\(tealiumVisitorId)"
    }

    /// Should fetch visitor profile based on interval set in the config or defaults to every 5 minutes
    var shouldFetchVisitorProfile: Bool {
        guard let refresh = tealiumConfig.visitorServiceRefresh else {
            return shouldFetch(basedOn: lastFetch, interval: VisitorServiceConstants.defaultRefreshInterval.milliseconds, environment: tealiumConfig.environment)
        }
        return shouldFetch(basedOn: lastFetch, interval: refresh.interval.milliseconds, environment: tealiumConfig.environment)
    }

    /// Calculates the milliseconds since the last time the visitor profile was fetched
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - currentDate: The current date/timestamp in milliseconds
    /// - Returns: `Int64` - milliseconds since last fetch
    func intervalSince(lastFetch: Date, _ currentDate: Date = Date()) -> Int64 {
        return currentDate.millisecondsFrom(earlierDate: lastFetch)
    }

    /// Checks if the profile should be fetched based on the date of last fetch,
    /// the interval set in the config (default 5 minutes) and the current environment.
    /// If the environment is dev or qa, the profile will be fetched every tracking call.
    ///
    /// - Parameters:
    ///   - lastFetch: The date the visitor profile was last retrieved
    ///   - interval: The interval, in milliseconds, between visitor profile retrieval
    ///   - environment: The environment set in TealiumConfig
    /// - Returns: `Bool` - whether or not the profile should be fetched
    func shouldFetch(basedOn lastFetch: Date?,
                     interval: Int64?,
                     environment: String) -> Bool {
        guard let lastFetch = lastFetch else {
            return true
        }
        guard environment == TealiumKey.prod else {
            return true
        }
        guard let interval = interval else {
            return true
        }
        let millisecondsFromLastFetch = intervalSince(lastFetch: lastFetch)
        return millisecondsFromLastFetch >= interval
    }

    /// Fetches the visitor profile from the visitor service endpoint
    ///
    /// - Parameter completion: Accepts a boolean to indicate if successful along with the updated profile retrieved
    func fetchVisitorProfile(_ completion: @escaping (FetchVisitorProfileResult) -> Void) {
        guard shouldFetchVisitorProfile else {
            completion(.success(nil))
            return
        }
        let request = URLRequest(url: URL(string: visitorServiceURL)!)
        sendURLRequest(request) { [weak self] result in
            switch result {
            case .success(let data):
                if let visitor = try? Tealium.jsonDecoder.decode(TealiumVisitorProfile.self, from: data) {
                    self?.visitorProfile = visitor
                    self?.lastFetch = Date()
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
        urlSession?.finishTealiumTasksAndInvalidate()
        urlSession = nil
    }

}
