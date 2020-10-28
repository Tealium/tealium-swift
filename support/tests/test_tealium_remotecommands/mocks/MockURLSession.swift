//
//  MockURLSession.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

class MockURLSession: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTask(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() { }
}

class MockURLSession304: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTask304(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask304(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask304(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() { }
}

class DataTask: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(TestTealiumHelper.loadStub(from: "example", type(of: self)), urlResponse, nil)
    }
}

class DataTask304: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 304, httpVersion: "1.1", headerFields: nil)
        completionHandler(nil, urlResponse, nil)
    }
}

class MockURLSessionError: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskError(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskError(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskError(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() { }
}

class DataTaskError: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    func resume() {
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: ["X-Error": "missing account/profile"])
        completionHandler(nil, urlResponse, nil)
    }

}

class MockURLSessionErrorNoResponse: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return NoResponseDataTaskError(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return NoResponseDataTaskError(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return NoResponseDataTaskError(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() { }
}

class NoResponseDataTaskError: DataTaskError {
    override func resume() {
        completionHandler(nil, nil, nil)
    }
}
