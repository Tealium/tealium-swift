//
//  MockURLSession.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import TealiumCore

extension DataTaskResult {
    private static func urlResponse(statusCode: Int, headerFields: [String: String]?) -> HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "someURL")!, statusCode: statusCode, httpVersion: "1.1", headerFields: headerFields)
    }
    static func success(withData data: Data?, statusCode: Int = 200, headers: [String: String]? = nil) -> DataTaskResult {
        return .success((urlResponse(statusCode: statusCode, headerFields: headers), data))
    }
    static func success<Obj: Codable>(with object: Obj, statusCode: Int = 200, headers: [String: String]? = nil) -> DataTaskResult {
        return .success(withData: try? JSONEncoder().encode(object), statusCode: statusCode, headers: headers)
    }
}

class MockURLSession: URLSessionProtocol {
    var isInvalidated = false
    var result: DataTaskResult?
    @ToAnyObservable<TealiumReplaySubject<URLRequest>>(TealiumReplaySubject<URLRequest>())
    var onRequestSent: TealiumObservable<URLRequest>
    
    class MockDataTask: URLSessionDataTaskProtocol {
        let completion: () -> Void
        init(completion: @escaping () -> Void) {
            self.completion = completion
        }
        func resume() {
            completion()
        }
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        let request = URLRequest(url: url)
        _onRequestSent.publish(request)
        return tealiumDataTask(with: request, completionHandler: completionHandler)
        
    }
    
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        _onRequestSent.publish(request)
        return tealiumDataTask(with: request.url!) { result in
            do {
                let tuple = try result.get()
                completionHandler(tuple.1, tuple.0, nil)
            } catch {
                completionHandler(nil, nil, error)
            }
        }
    }
    
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        MockDataTask {
            guard let result = self.result else {
                XCTFail("MockURLSession called with with no result")
                return
            }
            completionHandler(result)
        }
    }
    
    func finishTealiumTasksAndInvalidate() {
        isInvalidated = true
    }
    
    
}
