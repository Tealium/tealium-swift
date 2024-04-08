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
    private static func urlResponse(headerFields: [String: String]?) -> HTTPURLResponse? {
        HTTPURLResponse(url: URL(string: "someURL")!, statusCode: 200, httpVersion: "1.1", headerFields: headerFields)
    }
    static func success(with data: Data?, headers: [String: String]? = nil) -> DataTaskResult {
        return .success((urlResponse(headerFields: headers), data))
    }
    static func success<Obj: Codable>(with object: Obj, headers: [String: String]? = nil) -> DataTaskResult {
        return .success(with: try? JSONEncoder().encode(object), headers: headers)
    }
}

class MockURLSession: URLSessionProtocol {
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
        
    }
    
    
}
