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

extension TealiumConfigKey {
    static let tagManagementOverrideURL = "tagmanagement_override_url"
    static let tagManagementDelegate = "delegate"
    static let uiview = "ui_view"
    static let processPool = "wk_process_pool"
    static let wkConfig = "wk_config"
}

public extension TealiumConfig {

    /// Adds optional delegates to the WebView instance.
    var webViewDelegates: [WKNavigationDelegate]? {
        get {
            let weakDelegates = options[TealiumConfigKey.tagManagementDelegate] as? [Weak<WKNavigationDelegate>]
            return weakDelegates?.compactMap { $0.value }
        }
        set {
            options[TealiumConfigKey.tagManagementDelegate] = newValue?.map { Weak(value: $0) }
        }
    }

    /// Optionally sets a `WKProcessPool` for the Tealium WKWebView to use.
    /// Required if multiple webviews are in use; prevents issues with cookie setting.
    /// A singleton WKProcessPool instance should be passed that is used for all `WKWebView`s in your app.
    var webviewProcessPool: WKProcessPool? {
        get {
            options[TealiumConfigKey.processPool] as? WKProcessPool
        }

        set {
            options[TealiumConfigKey.processPool] = newValue
        }
    }

    /// Optionally sets a `WKWebViewConfiguration` for the Tealium WKWebView to use.
    /// Not normally required, but provides some additional customization options if requred.
    var webviewConfig: WKWebViewConfiguration {
        get {
            options[TealiumConfigKey.wkConfig] as? WKWebViewConfiguration ?? WKWebViewConfiguration()
        }

        set {
            options[TealiumConfigKey.wkConfig] = newValue
        }
    }

    /// Optional override for the tag management webview URL.
    var tagManagementOverrideURL: String? {
        get {
            options[TealiumConfigKey.tagManagementOverrideURL] as? String
        }

        set {
            options[TealiumConfigKey.tagManagementOverrideURL] = newValue
        }
    }

    /// Gets the URL to be loaded by the webview (mobile.html).
    ///
    /// - Returns: `URL` representing either the custom URL provided in the `TealiumConfig` object, or the default Tealium mCDN URL
    var webviewURL: URL? {
        if let overrideWebviewURL = tagManagementOverrideURL {
            return URL(string: overrideWebviewURL)
        } else {
            return URL(string: "\(TealiumValue.tiqBaseURL)\(self.account)/\(self.profile)/\(self.environment)/\(TealiumValue.tiqURLSuffix)")
        }
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    var rootView: UIView? {
        get {
            options[TealiumConfigKey.uiview] as? UIView
        }

        set {
            options[TealiumConfigKey.uiview] = newValue
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
    /// ￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    func updateRootView(_ view: UIView) {
        self.tagManagement?.setRootView(view)
    }

    /// Returns the WebView as soon as it's created
    ///
    /// If you are using XCode 14.3+ you can use this WebView instance to change the isInspectable property
    func getTagManagementWebView(_ completion: @escaping (WKWebView) -> Void) {
        self.tagManagement?.getWebView(completion)
    }
}

public extension Dispatchers {
    static let TagManagement = TagManagementModule.self
}

#endif
