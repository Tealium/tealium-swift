//
//  TealiumTagManagementUIWebViewDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 07/12/2018.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if tagmanagement
import TealiumCore
#endif

#if swift(>=4.2)
public typealias WebViewNavigationTypeAlias = UIWebView.NavigationType
#else
public typealias WebViewNavigationTypeAlias = UIWebViewNavigationType
#endif

extension TealiumTagManagementUIWebView: UIWebViewDelegate {

    /// Used to determine if a Remote Command should be triggered from a URLRequest
    public func webView(_ webView: UIWebView,
                        shouldStartLoadWith request: URLRequest,
                        navigationType: WebViewNavigationTypeAlias) -> Bool {

        var shouldStart = true

        // Broadcast request for any listeners (Remote command module)
        if let urlString = request.url?.absoluteString, urlString.hasPrefix(TealiumKey.tealiumURLScheme) {
            let notification = Notification(name: Notification.Name(TealiumKey.tagmanagementNotification),
                                            object: webView,
                                            userInfo: [TealiumKey.tagmanagementNotification: request])
            NotificationCenter.default.post(notification)
            // cancel load; not required for this request to load in the WebView
            // Avoids failed requests showing in WebView console
            return false
        }

        // Look for false from any delegate
        delegates.invoke {
            if $0.webView?(webView,
                           shouldStartLoadWith: request,
                           navigationType: navigationType) == false {
                shouldStart = false
            }
        }

        return shouldStart
    }

    /// Not used by Tealium. Forward to any listening delegates
    public func webViewDidStartLoad(_ webView: UIWebView) {
        delegates.invoke {
            $0.webViewDidStartLoad?(webView)
        }
    }

    /// Inform webview of load failure. Forward to any listening delegates.
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        delegates.invoke {
            $0.webView?(webView, didFailLoadWithError: error)
        }
        if webviewDidFinishLoading == true {
            return
        }
        webviewDidFinishLoading = true
        self.enableCompletion?(false, error)
    }

    /// Called when the WebView has finished loading a resource (DOM Complete)
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        webviewDidFinishLoading = true
        delegates.invoke {
            $0.webViewDidFinishLoad?(webView)
        }

        DispatchQueue.global(qos: .background).async {
            self.enableCompletion?(true, nil)
        }
    }
}
