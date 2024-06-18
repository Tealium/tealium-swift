//
//  MockURLSession.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
import XCTest

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return tealiumDataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        completionHandler(data, response, error)
        // check that referer is set correctly
        XCTAssertEqual(request.allHTTPHeaderFields!["Referer"]!, MomentsAPITests.standardReferer)
        return MockURLSessionDataTask()
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        let result: DataTaskResult
        if let error = error {
            result = .failure(error)
        } else if let response = response {
            result = .success((response, data))
        } else {
            result = .failure(HTTPError.unknown)
        }
        completionHandler(result)
        return MockURLSessionDataTask()
    }
    
    func finishTealiumTasksAndInvalidate() {

    }
    
    private class MockURLSessionDataTask: URLSessionDataTaskProtocol {
        func resume() {

        }
    }
}

class MockURLSessionCustomReferer: URLSessionProtocol {
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return tealiumDataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        completionHandler(data, response, error)
        // Check that custom referer is set correctly
        XCTAssertEqual(request.allHTTPHeaderFields!["Referer"]!, "https://tealium.com/")
        return MockURLSessionDataTask()
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        let result: DataTaskResult
        if let error = error {
            result = .failure(error)
        } else if let response = response {
            result = .success((response, data))
        } else {
            result = .failure(HTTPError.unknown)
        }
        completionHandler(result)
        return MockURLSessionDataTask()
    }
    
    func finishTealiumTasksAndInvalidate() {

    }
    
    private class MockURLSessionDataTask: URLSessionDataTaskProtocol {
        func resume() {

        }
    }
}



