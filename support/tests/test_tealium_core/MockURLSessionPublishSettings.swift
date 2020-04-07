//
//  MockURLSessionPublishSettings.swift
//  tealium-swift
//
//  Created by Craig Rouse on 21/01/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

class MockURLSessionPublishSettings: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTask(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTask(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() {
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
        let string = """
        <!--tealium tag management - mobile.webview ut4.0.202001151447, Copyright 2020 Tealium.com Inc. All Rights Reserved.-->
        <html>
        <head><title>Tealium Mobile Webview</title></head>
        <body>
        <script type="text/javascript">var utag_cfg_ovrd={noview:true};var mps = {"4":{"_is_enabled":"false","battery_saver":"false","dispatch_expiration":"-1","event_batch_size":"1","ivar_tracking":"false","mobile_companion":"false","offline_dispatch_limit":"-1","ui_auto_tracking":"false","wifi_only_sending":"false"},"5":{"_is_enabled":"true","battery_saver":"false","dispatch_expiration":"-1","enable_collect":"true","enable_s2s_legacy":"false","enable_tag_management":"true","event_batch_size":"4","minutes_between_refresh":"1.0","offline_dispatch_limit":"30","override_log":"dev","wifi_only_sending":"true"},"_firstpublish":"true"}</script>
        <script type="text/javascript" src="//tags.tiqcdn.com/utag/tealiummobile/demo/dev/utag.js"></script>
        </body>
        </html>

        """
        let data = string.data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(data, urlResponse, nil)
    }

}

class MockURLSessionPublishSettingsNoContent: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskNoContent(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTaskNoContent(completionHandler: completionHandler, url: with.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskNoContent: URLSessionDataTaskProtocol {
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
