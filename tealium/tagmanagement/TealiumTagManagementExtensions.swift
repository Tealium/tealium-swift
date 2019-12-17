//
//  TealiumTagManagementExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 07/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if tagmanagement
import TealiumCore
#endif

// MARK: EXTENSIONS

public extension TealiumConfig {

    /// Sets the default queue size for the Tag Management module. This queue is active until the webview has finished loading.
    ///￼
    /// - Parameter queueSize: `Int` representing the maximum queue size for Tag Management module requests
    func setTagManagementQueueSize(queueSize: Int) {
        optionalData[TealiumTagManagementConfigKey.maxQueueSize] = queueSize
    }

    /// Adds optional delegates to the WebView instance.
    ///￼
    /// - Parameter delegates: `[AnyObject]` Array of delegates, downcast from `AnyObject` due to different delegate APIs for `UIWebView` and `WKWebView`
    func setWebViewDelegates(_ delegates: [AnyObject]) {
        optionalData[TealiumTagManagementConfigKey.delegate] = delegates
    }

    /// Gets array of optional webview delegates from the `TealiumConfig` instance.
    ///
    /// - Returns: `[AnyObject]` representing `WKNavigationDelegate` or any future updated WebView delegate
    func getWebViewDelegates() -> [AnyObject]? {
        return optionalData[TealiumTagManagementConfigKey.delegate] as? [AnyObject]
    }

    /// Optional override for the tag management webview URL.
    ///￼
    /// - Parameter string: `String` representing the URL to be loaded by the webview. Must be a valid URL
    func setTagManagementOverrideURL(string: String) {
        optionalData[TealiumTagManagementConfigKey.overrideURL] = string
    }

    /// Gets the URL to be loaded by the webview (mobile.html).
    ///
    /// - Returns: `URL` representing either the custom URL provided in the `TealiumConfig` object, or the default Tealium mCDN URL
    func webviewURL() -> URL? {
        if let overrideWebviewURL = self.optionalData[TealiumTagManagementConfigKey.overrideURL] as? String {
            return URL(string: overrideWebviewURL)
        } else {
            return URL(string: "\(TealiumTagManagementKey.defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/mobile.html")
        }
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameter view: `UIView` instance for `WKWebView` to be attached to
    func setRootView(_ view: UIView) {
        optionalData[TealiumTagManagementConfigKey.uiview] = view
    }

    /// Checks if a specific root view has been provided in the `TealiumConfig` instance.
    ///
    /// - Returns: `UIView?` to be used.
    func getRootView() -> UIView? {
        return optionalData[TealiumTagManagementConfigKey.uiview] as? UIView
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
