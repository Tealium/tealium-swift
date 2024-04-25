//
//  MockURLSession.swift
//  tealium-swift
//
//  Created by Craig Rouse on 18/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

class MockURLSession: URLSessionProtocol {
    var data: Data?
    var response: HTTPURLResponse?
    var error: Error?
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return tealiumDataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }
    
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        completionHandler(data, response, error)
        return MockURLSessionDataTask()
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        let result: DataTaskResult
        if let error = error {
            result = .failure(error)
        } else if let response = response {
            result = .success((response, data))
        } else {
            result = .failure(HTTPError.unknown)  // Assuming HTTPError.unknown exists in your project
        }
        completionHandler(result)
        return MockURLSessionDataTask()
    }
    
    func finishTealiumTasksAndInvalidate() {
        // In the mock, this function can be left empty or used to reset mock states if needed.
    }
    
    private class MockURLSessionDataTask: URLSessionDataTaskProtocol {
        func resume() {
            // This method is intentionally left blank in the mock implementation.
        }
    }
}





