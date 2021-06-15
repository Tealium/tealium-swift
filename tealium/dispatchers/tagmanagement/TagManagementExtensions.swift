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
    
    /// Optionally sets a `WKProcessPool` for the Tealium WKWebView to use.
    /// Required if multiple webviews are in use; prevents issues with cookie setting.
    /// A singleton WKProcessPool instance should be passed that is used for all `WKWebView`s in your app.
    var webviewProcessPool: WKProcessPool? {
        get {
            options[TagManagementConfigKey.processPool] as? WKProcessPool
        }

        set {
            options[TagManagementConfigKey.processPool] = newValue
        }
    }
    
    /// Optionally sets a `WKWebViewConfiguration` for the Tealium WKWebView to use.
    /// Not normally required, but provides some additional customization options if requred.
    var webviewConfig: WKWebViewConfiguration {
        get {
            options[TagManagementConfigKey.wkConfig] as? WKWebViewConfiguration ?? WKWebViewConfiguration()
        }

        set {
            options[TagManagementConfigKey.wkConfig] = newValue
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
