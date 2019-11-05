//
//  URLSessionProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 09/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void

public protocol URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol
    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol
    func finishTealiumTasksAndInvalidate()
}

public protocol URLSessionDataTaskProtocol {
    func resume()
}
