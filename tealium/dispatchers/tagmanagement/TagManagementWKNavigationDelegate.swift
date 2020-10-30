//
//  TagManagementWKNavigationDelegate.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import WebKit
#if tagmanagement
import TealiumCore
#endif

extension TagManagementWKWebView: WKNavigationDelegate {

    /// Called when the WebView has finished loading a resource (DOM Complete)
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        if let url = webView.url,
           url == self.url {
            self.webviewStateDidChange(.loadSuccess, withError: nil)
        } else {
            self.webviewStateDidChange(.loadFailure, withError: TagManagementError.webViewNotYetReady)
        }

        // forward to any listening delegates
        delegates?.invoke {
            $0.webView?(webView, didFinish: navigation)
        }
    }

    /// Inform webview of load failure. Forward to any listening delegates.
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.webviewStateDidChange(.loadFailure, withError: error)
        delegates?.invoke {
            $0.webView?(webView, didFail: navigation, withError: error)
        }
    }

    /// Fix for server-side cookies not being set properly
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
              let url = navigationResponse.response.url else {
            decisionHandler(.cancel)
            return
        }

        /// Forces WKWebView to respect `Set-Cookie` response headers.
        /// Without this code, cookies set in this way are not sent on subsequent requests.
        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            cookies.forEach { cookie in
                if #available(iOS 11, *) {
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
        }

        decisionHandler(.allow)
    }

    /// Decides whether or not a resource should load.
    /// Remote Commands are intercepted here, and do not need to load requests in the WebView.
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let urlRequest = navigationAction.request
        var decisionAction: WKNavigationActionPolicy?
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix(TealiumKey.tealiumURLScheme) {
            let request = TealiumRemoteCommandRequest(data: [TealiumKey.tagmanagementNotification: urlRequest])
            moduleDelegate?.processRemoteCommandRequest(request)
            // prevents errors in webview by canceling load
            decisionHandler(.cancel)
            return
        }

        // Give any listening delegates a chance to respond
        delegates?.invoke {
            let customDecisionHandler: ((WKNavigationActionPolicy) -> Void) = { actionPolicy in
                switch actionPolicy {
                case .allow:
                    decisionAction = .allow
                case .cancel:
                    decisionAction = .cancel
                @unknown default:
                    decisionAction = .cancel
                }
            }
            $0.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: customDecisionHandler)
        }

        // check response from delegates, or proceed to allow the request
        if let decisionAction = decisionAction {
            decisionHandler(decisionAction)
        } else {
            decisionHandler(.allow)
        }
    }

    /// Not used by Tealium. Forward to any listening delegates
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegates?.invoke {
            $0.webViewWebContentProcessDidTerminate?(webView)
        }
    }

    /// Not used by Tealium. Forward to any listening delegates
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        delegates?.invoke {
            $0.webView?(webView, didCommit: navigation)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if self.currentState.value == InternalWebViewState.didFailToLoad.rawValue {
            return
        }
        self.webviewStateDidChange(.loadFailure, withError: error)
        delegates?.invoke {
            $0.webView?(webView, didFail: navigation, withError: error)
        }
    }
}
#endif
