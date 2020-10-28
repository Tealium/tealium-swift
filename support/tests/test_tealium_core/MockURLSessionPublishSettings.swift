//
//  MockURLSessionPublishSettings.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore

class MockURLSessionPublishSettings: URLSessionProtocol {
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

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTask(completionHandler: completionHandler, url: request.url!)
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

class MockURLSessionPublishSettingsExtraContent: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskExtraContent(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskExtraContent(completionHandler: completionHandler, url: url)
    }

    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskExtraContent(completionHandler: completionHandler, url: request.url!)
    }

    func finishTealiumTasksAndInvalidate() {
    }

}

class DataTaskExtraContent: URLSessionDataTaskProtocol {
    let completionHandler: DataTaskCompletion
    let url: URL
    init(completionHandler: @escaping DataTaskCompletion,
         url: URL) {
        self.completionHandler = completionHandler
        self.url = url
    }
    // swiftlint:disable function_body_length
    func resume() {
        let string = """

        <!--tealium tag management - mobile.webview ut4.0.201912051554, Copyright 2019 Tealium.com Inc. All Rights Reserved.-->
        <html>
        <head><title>Tealium Mobile Webview</title><script>var w = window;
        if (w.performance || w.mozPerformance || w.msPerformance || w
            .webkitPerformance) {
            var d = document;
            AKSB = w.AKSB || {}, AKSB.q = AKSB.q || [], AKSB.mark = AKSB.mark ||
                function(e, _) {
                    AKSB.q.push(["mark", e, _ || (new Date).getTime()])
                }, AKSB.measure = AKSB.measure || function(e, _, t) {
                    AKSB.q.push(["measure", e, _, t || (new Date).getTime()])
                }, AKSB.done = AKSB.done || function(e) {
                    AKSB.q.push(["done", e])
                }, AKSB.mark("firstbyte", (new Date).getTime()), AKSB.prof = {
                    custid: "219317",
                    ustr: "",
                    originlat: "0",
                    clientrtt: "14",
                    ghostip: "202.7.177.68",
                    ipv6: false,
                    pct: "10",
                    clientip: "110.175.66.216",
                    requestid: "344e9ba3",
                    region: "14190",
                    protocol: "h2",
                    blver: 14,
                    akM: "a",
                    akN: "ae",
                    akTT: "O",
                    akTX: "1",
                    akTI: "344e9ba3",
                    ai: "193240",
                    ra: "false",
                    pmgn: "",
                    pmgi: "",
                    pmp: "",
                    qc: ""
                },
                function(e) {
                    var _ = d.createElement("script");
                    _.async = "async", _.src = e;
                    var t = d.getElementsByTagName("script"),
                        t = t[t.length - 1];
                    t.parentNode.insertBefore(_, t)
                }(("https:" === d.location.protocol ? "https:" : "http:") +
                    "//ds-aksb-a.akamaihd.net/aksb.min.js")
        }</script></head>
        <body>
        <script type="text/javascript">var utag_cfg_ovrd={noview:true};var mps = {"4":{"_is_enabled":"false","battery_saver":"false","dispatch_expiration":"-1","event_batch_size":"10","ivar_tracking":"false","mobile_companion":"false","offline_dispatch_limit":"-1","ui_auto_tracking":"false","wifi_only_sending":"false"},"5":{"_is_enabled":"true","battery_saver":"true","dispatch_expiration":"1","enable_collect":"true","enable_s2s_legacy":"false","enable_tag_management":"true","event_batch_size":"10","minutes_between_refresh":"1.0","offline_dispatch_limit":"50","override_log":"dev","wifi_only_sending":"true"},"_firstpublish":"true"}</script>
        <script type="text/javascript" src="//tags.tiqcdn.com/utag/tealiummobile/demo/dev/utag.js"></script>
        <script>var w = window;
        if (w.performance || w.mozPerformance || w.msPerformance || w
            .webkitPerformance) {
            var d = document;
            AKSB = w.AKSB || {}, AKSB.q = AKSB.q || [], AKSB.mark = AKSB.mark ||
                function(e, _) {
                    AKSB.q.push(["mark", e, _ || (new Date).getTime()])
                }, AKSB.measure = AKSB.measure || function(e, _, t) {
                    AKSB.q.push(["measure", e, _, t || (new Date).getTime()])
                }, AKSB.done = AKSB.done || function(e) {
                    AKSB.q.push(["done", e])
                }, AKSB.mark("firstbyte", (new Date).getTime()), AKSB.prof = {
                    custid: "219317",
                    ustr: "",
                    originlat: "0",
                    clientrtt: "14",
                    ghostip: "202.7.177.68",
                    ipv6: false,
                    pct: "10",
                    clientip: "110.175.66.216",
                    requestid: "344e9ba3",
                    region: "14190",
                    protocol: "h2",
                    blver: 14,
                    akM: "a",
                    akN: "ae",
                    akTT: "O",
                    akTX: "1",
                    akTI: "344e9ba3",
                    ai: "193240",
                    ra: "false",
                    pmgn: "",
                    pmgi: "",
                    pmp: "",
                    qc: ""
                },
                function(e) {
                    var _ = d.createElement("script");
                    _.async = "async", _.src = e;
                    var t = d.getElementsByTagName("script"),
                        t = t[t.length - 1];
                    t.parentNode.insertBefore(_, t)
                }(("https:" === d.location.protocol ? "https:" : "http:") +
                    "//ds-aksb-a.akamaihd.net/aksb.min.js")
        }</script>
        </body>
        </html>


        """
        let data = string.data(using: .utf8)!
        let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        completionHandler(data, urlResponse, nil)
    }

}

class MockURLSessionPublishSettingsNoContent: URLSessionProtocol {
    func tealiumDataTask(with url: URL, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTaskProtocol {
        return DataTaskNoContent(completionHandler: { data, response, error in
            if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let response = response {
                completionHandler(.success((response as? HTTPURLResponse, data)))
            }
        }, url: url)
    }

    func tealiumDataTask(with url: URL, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        return DataTaskNoContent(completionHandler: completionHandler, url: url)
    }

    // typealias DataTaskCompletion = (Data?, URLResponse?, Error?) -> Void
    func tealiumDataTask(with request: URLRequest, completionHandler: @escaping DataTaskCompletion) -> URLSessionDataTaskProtocol {
        //        let completion = DataTaskCompletion(nil, nil, nil)
        return DataTaskNoContent(completionHandler: completionHandler, url: request.url!)
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
