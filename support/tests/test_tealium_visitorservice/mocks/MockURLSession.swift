//
//  MockURLSession.swift
//  tealium-swift
//
//  Created by Craig Rouse on 09/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
//@testable import TealiumCollect
@testable import TealiumVisitorService
@testable import TealiumCore

class MockURLSession: URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func dataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
//        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTask(completionHandler: completionHandler, url: with.url!)
    }

    func finishTasksAndInvalidate() {

    }

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
        completionHandler(loadStub(from: "visitor", with: "json", for: VisitorProfileTests.self), urlResponse, nil)
    }

}

class MockURLSessionError: URLSessionProtocol {
    func dataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskError(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func dataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTaskError(completionHandler: completionHandler, url: with.url!)
    }

    func finishTasksAndInvalidate() {

    }

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
