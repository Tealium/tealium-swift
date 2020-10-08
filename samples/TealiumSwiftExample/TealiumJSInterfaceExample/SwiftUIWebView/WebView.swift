//
//  WebView.swift
//  SwiftUIWebView
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import UIKit
import WebKit

struct WebView: UIViewRepresentable {

    var url: WebUrlType
    @ObservedObject var viewModel: ViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self.makeCoordinator(), name: "tealium")
        configuration.preferences = preferences

        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if url == .localUrl {
            if let url = Bundle.main.url(forResource: "LocalWebsite", withExtension: "html", subdirectory: "www") {
                webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        } else if url == .publicUrl {
            if let url = URL(string: "https://tags.tiqcdn.com/utag/services-christina/mobile-a/dev/mobile.html") {
                webView.load(URLRequest(url: url))
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var valueSubscriber: AnyCancellable?
        var webViewNavigationSubscriber: AnyCancellable?

        init(_ uiWebView: WebView) {
            self.parent = uiWebView
        }

        deinit {
            valueSubscriber?.cancel()
            webViewNavigationSubscriber?.cancel()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.title") { response, error in
                if let error = error {
                    print("Error getting title")
                    print(error.localizedDescription)
                }

                guard let title = response as? String else {
                    return
                }

                self.parent.viewModel.showWebTitle.send(title)
            }
            valueSubscriber = parent.viewModel.valuePublisher.receive(on: RunLoop.main).sink(receiveValue: { value in
                let javascriptFunction = "valueGotFromIOS(\(value));"
                webView.evaluateJavaScript(javascriptFunction) { _, error in
                    if let error = error {
                        print("Error calling javascript:valueGotFromIOS()")
                        print(error.localizedDescription)
                    } else {
                        print("Called javascript:valueGotFromIOS()")
                    }
                }
            })
            self.parent.viewModel.showLoader.send(false)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.viewModel.showLoader.send(false)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.showLoader.send(false)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.viewModel.showLoader.send(true)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.viewModel.showLoader.send(true)
            self.webViewNavigationSubscriber = self.parent.viewModel.webViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveValue: { navigation in
                switch navigation {
                case .backward:
                    if webView.canGoBack {
                        webView.goBack()
                    }
                case .forward:
                    if webView.canGoForward {
                        webView.goForward()
                    }
                case .reload:
                    webView.reload()
                }
            })
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let host = navigationAction.request.url?.host {
                if host == "restricted.com" {
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}
