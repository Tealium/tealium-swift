//
//  CollectEventDispatcher.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

class CollectEventDispatcher: CollectProtocol, LoggingDataToStringConverter {

    let urlSession: URLSessionProtocol
    var logger: TealiumLoggerProtocol?
    static var defaultDispatchBaseURL = "https://collect.tealiumiq.com"
    static var singleEventPath = "/event/"
    static var batchEventPath = "/bulk-event/"
    static var tealiumDomain = ".tealiumiq.com"

    var batchEventDispatchURL: String?
    var singleEventDispatchURL: String?

    /// Initializes dispatcher￼.
    ///
    /// - Parameters:
    ///     - dispatchURL:`String` representation of the dispatch URL￼
    ///     - urlSession: `URLSession` to use for the dispatch (overridable for unit tests)￼
    ///     - completion: `ModuleCompletion?` Completion handler to run when the dispatcher has finished initializing
    init(config: TealiumConfig,
         urlSession: URLSessionProtocol = CollectEventDispatcher.urlSession,
         completion: ModuleCompletion? = nil) {
        self.urlSession = urlSession
        self.logger = config.logger
        setUpUrls(config: config)
        completion?((.success(true), nil))
    }

    func setUpUrls(config: TealiumConfig) {
        if let overrideUrl = config.overrideCollectURL,
           overrideUrl.isValidUrl {
            self.singleEventDispatchURL = overrideUrl
        } else {
            if let overrideDomain = config.overrideCollectDomain {
                singleEventDispatchURL = "https://\(overrideDomain)\(CollectEventDispatcher.singleEventPath)"
            } else {
                singleEventDispatchURL = "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.singleEventPath)"
            }
        }

        if let overrideBatchUrl = config.overrideCollectBatchURL,
           overrideBatchUrl.isValidUrl {
            self.batchEventDispatchURL = overrideBatchUrl
        } else {
            if let overrideDomain = config.overrideCollectDomain {
                batchEventDispatchURL = "https://\(overrideDomain)\(CollectEventDispatcher.batchEventPath)"
            } else {
                batchEventDispatchURL = "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.batchEventPath)"
            }
        }
    }

    /// - Returns: `URLSession` -  An ephemeral URLSession instance
    class var urlSession: URLSession {
        let config = URLSessionConfiguration.ephemeral
        return URLSession(configuration: config)
    }

    func dispatch(data: [String: Any],
                  completion: ModuleCompletion?) {
        dispatch(data: data, url: nil, completion: completion)
    }

    /// Dispatches data to an HTTP endpoint, then calls optional completion block when finished￼.
    ///
    /// - Parameters:
    ///     - data: `[String:Any]` of variables to be dispatched￼
    ///     - url: `String?` containing the dispatch URL to use. Defaults to single event dispatch url.￼
    ///     - completion: `ModuleCompletion?` Optional completion block to be called when operation complete
    func dispatch(data: [String: Any],
                  url: String? = nil,
                  completion: ModuleCompletion?) {
        if let jsonString = convertData(data, toStringWith: { try $0.toJSONString() }),
           let url = url ?? singleEventDispatchURL,
           let urlRequest = NetworkUtils.urlPOSTRequestWithJSONString(jsonString, dispatchURL: url) {
            sendURLRequest(urlRequest, completion)
        } else {
            completion?((.failure(CollectError.noDataToTrack), nil))
        }
    }

    /// Dispatches data to an HTTP endpoint, then calls optional completion block when finished.
    ///
    /// - Parameters:
    ///     - data: `[String:Any]` containing the nested data structure for a batch dispatch
    ///     - completion: `ModuleCompletion?` Optional completion block to be called when operation complete
    func dispatchBatch(data: [String: Any],
                       completion: ModuleCompletion?) {
        dispatch(data: data, url: batchEventDispatchURL, completion: completion)
    }

    /// Sends a URLRequest, then calls the completion handler, passing success/failures back to the completion handler￼.
    ///
    /// - Parameters:
    ///     - request: `URLRequest` object￼
    ///     - completion: `ModuleCompletion?` Optional completion block to handle success/failure
    func sendURLRequest(_ request: URLRequest,
                        _ completion: ModuleCompletion?) {
        let task = urlSession.tealiumDataTask(with: request) { _, response, error in
            if let error = error as? URLError {
                completion?((.failure(error), nil))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion?((.failure(CollectError.unknownResponseType), nil))
                return
            }
            // error only indicates "no response from server. 400 responses are considered successful
            if let errorHeader = response.allHeaderFields[CollectKey.errorHeaderKey] as? String {
                completion?((.failure(CollectError.xErrorDetected), ["error": errorHeader]))
                return
            }
            guard (200..<300).contains(response.statusCode) else {
                completion?((.failure(CollectError.non200Response), nil))
                return
            }
            completion?((.success(true), nil))
        }
        task.resume()
    }

    deinit {
        urlSession.finishTealiumTasksAndInvalidate()
    }

}
