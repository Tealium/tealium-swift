//
//  MockTagManagementWebView.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
#if os(iOS)
import WebKit
#endif

class MockTagManagementWebView: TagManagementProtocol {
    var url: URL?

    var reloadCallCount = 0
    var evaluateJavascriptCallCount = 0
    var success: Bool

    init(success: Bool) {
        self.success = success
    }

    func enable(webviewURL: URL?, delegates: [WKNavigationDelegate]?, view: UIView?, completion: ((Bool, Error?) -> Void)?) {
        completion?(success, success ? nil : NSError(domain: "Mock-Webview", code: 1))
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

    func setRootView(_ view: UIView) -> Bool {
        return true
    }

    func getWebView(_ completion: @escaping (WKWebView) -> Void) {
        
    }

}

class MockQueryParamsProvider: Collector, QueryParameterProvider {
    var data: [String : Any]? = nil
    
    static let defaultItems = [URLQueryItem(name: "test", value: "value")]
    required convenience init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String : Any]?)) -> Void) {
        self.init(items: MockQueryParamsProvider.defaultItems, delay: 1)
    }
    
    
    var id: String = "Mock Query Params Provider"
    var config: TealiumConfig = TealiumConfig(account: "", profile: "", environment: "")
    
    
    let items: [URLQueryItem]
    let secondsDelay: TimeInterval
    init(items: [URLQueryItem], delay seconds: TimeInterval) {
        self.items = items
        self.secondsDelay = seconds
    }
    
    func provideParameters(completion: @escaping ([URLQueryItem]) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + secondsDelay) {
            completion(self.items)
        }
    }
}
