//
//  TagManagementExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import UIKit
import WebKit
#if tagmanagement
import TealiumCore
#endif

public extension TealiumConfig {

    /// Adds optional delegates to the WebView instance.
    var webViewDelegates: [WKNavigationDelegate]? {
        get {
            options[TagManagementConfigKey.delegate] as? [WKNavigationDelegate]
        }

        set {
            options[TagManagementConfigKey.delegate] = newValue
        }
    }

    /// Optional override for the tag management webview URL.
    var tagManagementOverrideURL: String? {
        get {
            options[TagManagementConfigKey.overrideURL] as? String
        }

        set {
            options[TagManagementConfigKey.overrideURL] = newValue
        }
    }

    /// Gets the URL to be loaded by the webview (mobile.html).
    ///
    /// - Returns: `URL` representing either the custom URL provided in the `TealiumConfig` object, or the default Tealium mCDN URL
    var webviewURL: URL? {
        if let overrideWebviewURL = tagManagementOverrideURL {
            return URL(string: overrideWebviewURL)
        } else {
            return URL(string: "\(TagManagementKey.defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/\(TealiumValue.tiqURLSuffix)")
        }
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    var rootView: UIView? {
        get {
            options[TagManagementConfigKey.uiview] as? UIView
        }

        set {
            options[TagManagementConfigKey.uiview] = newValue
        }
    }

    /// If `true` a cookie observer should be added in order to successfully migrate all cookies. If `false`, multiple cookie observers are present which may cause some cookies to not migrate.
    var shouldAddCookieObserver: Bool {
        get {
            return options[TagManagementConfigKey.cookieObserver] as? Bool ?? true
        }

        set {
            options[TagManagementConfigKey.cookieObserver] = newValue
        }
    }

}

public extension Tealium {

    /// - Returns: `TealiumTagManagementProtocol` (`WKWebView` for iOS11+)
    internal var tagManagement: TagManagementProtocol? {
        let module = zz_internal_modulesManager?.modules.first {
            $0 is TagManagementModule
        }

        return (module as? TagManagementModule)?.tagManagement
    }

    /// Sets a new root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    func updateRootView(_ view: UIView) {
        self.tagManagement?.setRootView(view, completion: nil)
    }
}

public extension Dispatchers {
    static let TagManagement = TagManagementModule.self
}

#endif
