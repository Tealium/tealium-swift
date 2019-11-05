//
//  TealiumURLSession.swift
//  tealium-swift
//
//  Created by Craig Rouse on 03/10/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

extension URLSession: URLSessionProtocol {
    public func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return (dataTask(with: url, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
    
    public func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return (dataTask(with: with, completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
    
    public func finishTealiumTasksAndInvalidate() {
        finishTasksAndInvalidate()
    }
    
}

extension URLSessionDataTask: URLSessionDataTaskProtocol {}
