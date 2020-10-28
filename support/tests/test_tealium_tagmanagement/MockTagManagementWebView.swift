//
//  MockTagManagementWebView.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
import WebKit

class MockTagManagementWebView: TagManagementProtocol {

    var reloadCallCount = 0
    var evaluateJavascriptCallCount = 0
    var success: Bool

    init(success: Bool) {
        self.success = success
    }

    func enable(webviewURL: URL?, delegates: [WKNavigationDelegate]?, shouldAddCookieObserver: Bool, view: UIView?, completion: ((Bool, Error?) -> Void)?) {

    }

    func disable() {

    }

    var isWebViewReady: Bool {
        if success {
            return true
        } else {
            return false
        }
    }

    func reload(_ completion: @escaping TealiumCompletion) {
        reloadCallCount += 1
        if success {
            completion(true, nil, nil)
        } else {
            completion(false, nil, nil)
        }

    }

    func track(_ data: [String: Any], completion: ((Bool, [String: Any], Error?) -> Void)?) {

    }

    func trackMultiple(_ data: [[String: Any]], completion: ((Bool, [String: Any], Error?) -> Void)?) {

    }

    func evaluateJavascript(_ jsString: String, _ completion: (([String: Any]) -> Void)?) {
        evaluateJavascriptCallCount += 1
    }

    func setWebViewDelegates(_ delegates: [WKNavigationDelegate]) {

    }

    func removeWebViewDelegates(_ delegates: [WKNavigationDelegate]) {

    }

    func setRootView(_ view: UIView, completion: ((Bool) -> Void)?) {

    }

}
