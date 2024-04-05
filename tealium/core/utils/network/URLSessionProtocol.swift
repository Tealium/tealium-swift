//
//  URLSessionProtocol.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
public typealias DataTaskResult = Result<(HTTPURLResponse?, Data?), Error>

public protocol URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol
    func finishTealiumTasksAndInvalidate()
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}
