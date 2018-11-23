//
//  TealiumCollectPostDispatcher.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/31/18.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

class TealiumCollectPostDispatcher: TealiumCollectProtocol {

    var urlSession: URLSession?
    var urlSessionConfiguration: URLSessionConfiguration?
    var dispatchURL: String
    static var defaultDispatchURL = "https://collect.tealiumiq.com/event/"

    init(dispatchURL: String, _ completion: @escaping ((_ dispatcher: TealiumCollectPostDispatcher?) -> Void)) {
        // not compatible with vdata endpoint - default to event endpoint
        if dispatchURL.contains("vdata/i.gif") {
            self.dispatchURL = TealiumCollectPostDispatcher.defaultDispatchURL
        } else {
            self.dispatchURL = dispatchURL
        }
        self.setupURLSession {
            // pass instance of self for use in unit tests
            completion(self)
        }
    }

    func setupURLSession(_ completion: (() -> Void)?) {
        self.urlSessionConfiguration = URLSessionConfiguration.default
        if let urlSessionConfiguration = self.urlSessionConfiguration {
            self.urlSession = URLSession(configuration: urlSessionConfiguration, delegate: nil, delegateQueue: nil)
        }
        completion?()
    }

    func dispatch(data: [String: Any],
                  completion: TealiumCompletion?) {
        if let jsonString = jsonStringWithDictionary(data), let urlRequest = urlPOSTRequestWithJSONString(jsonString, dispatchURL: dispatchURL) {
            sendURLRequest(urlRequest, completion)
        } else {
            completion?(false, nil, TealiumCollectError.noDataToTrack)
        }
    }

    func sendURLRequest(_ request: URLRequest, _ completion: TealiumCompletion?) {
        if let urlSession = self.urlSession {
            let task = urlSession.dataTask(with: request) { _, response, error in
                if let status = response as? HTTPURLResponse {
                    // error only indicates "no response from server. 400 responses are considered successful
                    if let error = error {
                        completion?(false, nil, error)
                    } else {
                        if let errorHeader = status.allHeaderFields[TealiumCollectKey.errorHeaderKey] as? String {
                            completion?(false, ["error": errorHeader], TealiumCollectError.xErrorDetected)
                        } else if status.statusCode != 200 {
                            completion?(false, nil, TealiumCollectError.non200Response)
                        } else {
                            completion?(true, nil, nil)
                        }
                    }
                }
            }
            task.resume()
        }
    }

    deinit {
        urlSessionConfiguration = nil
        urlSession?.finishTasksAndInvalidate()
        urlSession = nil
    }

}
