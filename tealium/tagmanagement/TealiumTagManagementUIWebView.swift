// 
//  TealiumTagManagementUIWebView.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/6/2018.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if tagmanagement
import TealiumCore
#endif
#if TEST
#else
#if os(iOS)
import UIKit
#endif

/// TIQ Supported dispatch service Module. Utilizes older but simpler UIWebView vs. newer WKWebView.
public class TealiumTagManagementUIWebView: NSObject, TealiumTagManagementProtocol {

    var delegates = TealiumMulticastDelegate<UIWebViewDelegate>()
    var webviewDidFinishLoading = false
    var account: String = ""
    var profile: String = ""
    var environment: String = ""
    var urlString: String?
    var webview: UIWebView?
    var enableCompletion: ((Bool, Error?) -> Void)?

    /// Enables the webview. Called by the webview module at init time.
    ///
    /// - Parameters:
    /// - webviewURL: The URL (typically for "mobile.html") to be loaded by the webview
    /// - shouldMigrateCookies: Indicates whether cookies should be migrated from HTTPCookieStore (UIWebView).
    /// - completion: completion block to be called when the webview has finished loading
    public func enable(webviewURL: URL?,
                       shouldMigrateCookies: Bool,
                       delegates: [AnyObject]?,
                       view: UIView?,
                       completion: ((Bool, Error?) -> Void)?) {
        if self.webview != nil {
            // WebView already enabled.
            return
        }
        if let delegates = delegates {
            self.setWebViewDelegates(delegates)
        }
        self.enableCompletion = completion
        self.setupWebview(forURL: webviewURL)
    }

    /// Not required for UIWebView
    public func setRootView(_ view: UIView,
                            completion: ((Bool) -> Void)?) {

    }

    /// Adds optional delegates to the WebView instance
    ///
    /// - Parameter delegates: Array of delegates, downcast from AnyObject due to different delegate APIs for UIWebView and WKWebView
    public func setWebViewDelegates(_ delegates: [AnyObject]) {
        delegates.forEach { delegate in
            if let delegate = delegate as? UIWebViewDelegate {
                self.delegates.add(delegate)
            }
        }
    }

    /// Removes optional delegates for the WebView instance
    ///
    /// - Parameter delegates: Array of delegates, downcast from AnyObject due to different delegate APIs for UIWebView and WKWebView
    public func removeWebViewDelegates(_ delegates: [AnyObject]) {
        delegates.forEach { delegate in
            if let delegate = delegate as? UIWebViewDelegate {
                self.delegates.remove(delegate)
            }
        }
    }

    /// Configures an instance of UIWebView for later use.
    ///
    /// - Parameter forURL: The URL (typically for mobile.html) to load in the webview
    func setupWebview(forURL url: URL?) {
        self.webview = UIWebView()
        self.webview?.delegate = self
        guard let webview = webview else {
            self.enableCompletion?(false, TealiumWebviewError.webviewNotInitialized)
            return
        }
        guard let url = url else {
            self.enableCompletion?(false, TealiumWebviewError.webviewURLMissing)
            return
        }
        let request = URLRequest(url: url)
        DispatchQueue.main.async {
            webview.loadRequest(request)
        }
    }

    /// Internal webview status check.
    ///
    /// - Returns: Bool indicating whether or not the internal webview is ready for dispatching.
    public func isWebViewReady() -> Bool {
        guard nil != webview else {
            return false
        }
        if webviewDidFinishLoading == false {
            return false
        }

        return true
    }

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    /// - data: [String:Any] Dictionary of preferably String or [String] values.
    /// - completion: Optional completion handler to call when call completes.
    public func track(_ data: [String: Any], completion: ((Bool, [String: Any], Error?) -> Void)?) {
        guard let javascriptString = data.tealiumJavaScriptTrackCall else {
            completion?(false,
                        ["original_payload": data, "sanitized_payload": data],
                        TealiumTagManagementError.couldNotJSONEncodeData)
            return
        }
        var info = [String: Any]()
        info[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        info[TealiumTagManagementKey.jsCommand] = javascriptString
        info += [TealiumTagManagementKey.payload: data]
        self.evaluateJavascript(javascriptString) { result in
            info += result
            completion?(true, info, nil)
        }
    }

    /// Handles JavaScript evaluation on the WKWebView instance
    ///
    /// - Parameters:
    /// - jsString: The JavaScript call to be executed in the webview
    /// - completion: Optional completion block to be called after the JavaScript call completes
    public func evaluateJavascript(_ jsString: String, _ completion: (([String: Any]) -> Void)?) {
        var info = [String: Any]()
        DispatchQueue.main.async {
            if let result = self.webview?.stringByEvaluatingJavaScript(from: jsString) {
                info += [TealiumTagManagementKey.jsResult: result]
                completion?(info)
            }
        }
    }

    /// Called when the module needs to disable the webview
    public func disable() {
        self.webview?.stopLoading()
        self.webview = nil
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.webview?.stopLoading()
        self.webview?.delegate = nil
        self.webview = nil
    }
}
#endif
