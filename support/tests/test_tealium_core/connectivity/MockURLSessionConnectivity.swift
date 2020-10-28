//
//  MockURLSessionConnectivity.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

class ConnectivityDataTaskNoConnection: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        completionHandler(nil, nil, URLError(.notConnectedToInternet))
    }

}

class MockURLSessionConnectivityNoConnection: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return ConnectivityDataTaskNoConnection(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return ConnectivityDataTaskNoConnection(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return ConnectivityDataTaskNoConnection(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class ConnectivityDataTaskWithConnection: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        completionHandler(nil, nil, nil)
    }

}

class MockURLSessionConnectivityWithConnection: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return ConnectivityDataTaskWithConnection(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return ConnectivityDataTaskWithConnection(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return ConnectivityDataTaskWithConnection(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}
