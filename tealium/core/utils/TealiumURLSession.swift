//
//  TealiumURLSession.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public enum HTTPError: Error {
    case transportError(Error)
    case serverSideError(Int)
    case unknown
}

extension URLSession: URLSessionProtocol {
    public func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return (dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }

    public func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }

    public func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {

        return dataTask(with: url) { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completionHandler(.failure(HTTPError.unknown))
                return
            }

            let status = response.statusCode
            guard (200...299).contains(status) else {
                completionHandler(.failure(HTTPError.serverSideError(status)))
                return
            }
            completionHandler(.success((response, data)))
        }
    }

    public func finishTealiumTasksAndInvalidate() {
        finishTasksAndInvalidate()
    }

}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
