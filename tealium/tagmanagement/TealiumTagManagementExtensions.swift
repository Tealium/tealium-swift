//
//  TealiumTagManagementExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 07/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//
#if os(iOS)
import Foundation
import UIKit
import WebKit
#if tagmanagement
import TealiumCore
#endif

// MARK: EXTENSIONS

public extension TealiumConfig {

    /// Adds optional delegates to the WebView instance.
    ///￼
    /// - Parameter delegates: `[WKNavigationDelegate]` Array of delegates.
    @available(*, deprecated, message: "Please switch to config.webViewDelegates")
    func setWebViewDelegates(_ delegates: [WKNavigationDelegate]) {
        webViewDelegates = delegates
    }

    /// Gets array of optional webview delegates from the `TealiumConfig` instance.
    ///
    /// - Returns: `[WKNavigationDelegate]`
    @available(*, deprecated, message: "Please switch to config.webViewDelegates")
    func getWebViewDelegates() -> [WKNavigationDelegate]? {
        webViewDelegates
    }

    var webViewDelegates: [WKNavigationDelegate]? {
        get {
            optionalData[TealiumTagManagementConfigKey.delegate] as? [WKNavigationDelegate]
        }

        set {
            optionalData[TealiumTagManagementConfigKey.delegate] = newValue
        }
    }

    /// Optional override for the tag management webview URL.
    ///￼
    /// - Parameter string: `String` representing the URL to be loaded by the webview. Must be a valid URL
    @available(*, deprecated, message: "Please switch to config.tagManagementOverrideURL")
    func setTagManagementOverrideURL(string: String) {
        tagManagementOverrideURL = string
    }

    var tagManagementOverrideURL: String? {
        get {
            optionalData[TealiumTagManagementConfigKey.overrideURL] as? String
        }

        set {
            optionalData[TealiumTagManagementConfigKey.overrideURL] = newValue
        }
    }

    /// Gets the URL to be loaded by the webview (mobile.html).
    ///
    /// - Returns: `URL` representing either the custom URL provided in the `TealiumConfig` object, or the default Tealium mCDN URL
    var webviewURL: URL? {
        if let overrideWebviewURL = tagManagementOverrideURL {
            return URL(string: overrideWebviewURL)
        } else {
            return URL(string: "\(TealiumTagManagementKey.defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/mobile.html")
        }
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    @available(*, deprecated, message: "Please switch to config.rootView")
    func setRootView(_ view: UIView) {
        rootView = view
    }

    /// Checks if a specific root view has been provided in the `TealiumConfig` instance.
    ///
    /// - Returns: `UIView?` to be used.
    @available(*, deprecated, message: "Please switch to config.rootView")
    func getRootView() -> UIView? {
        rootView
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    var rootView: UIView? {
        get {
            optionalData[TealiumTagManagementConfigKey.uiview] as? UIView
        }

        set {
            optionalData[TealiumTagManagementConfigKey.uiview] = newValue
        }
    }

    var shouldAddCookieObserver: Bool {
        get {
            return optionalData[TealiumTagManagementConfigKey.cookieObserver] as? Bool ?? true
        }

        set {
            optionalData[TealiumTagManagementConfigKey.cookieObserver] = newValue
        }
    }

}

#if TEST
#else
public extension Tealium {

    /// - Returns: `TealiumTagManagementProtocol` (`WKWebView` for iOS11+)
    func tagManagement() -> TealiumTagManagementProtocol? {
        guard let module = modulesManager.getModule(forName: TealiumTagManagementKey.moduleName) as? TealiumTagManagementModule else {
            return nil
        }

        return module.tagManagement
    }

    /// Sets a new root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    func updateRootView(_ view: UIView) {
        self.tagManagement()?.setRootView(view, completion: nil)
    }
}
#endif
#endif
