//
//  TealiumTagManagementProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/8/2018
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit

public protocol TealiumTagManagementProtocol {

    /// Enables the webview. Called by the webview module at init time.
    ///
    /// - Parameters:
    /// - webviewURL: The URL (typically for "mobile.html") to be loaded by the webview
    /// - shouldMigrateCookies: Indicates whether cookies should be migrated from HTTPCookieStore (UIWebView)
    /// - view: Optional UIView instance to use for WKWebView. If not passed, this is auto-detected. Required for complex view hierarchies.
    /// - completion: completion block to be called when the webview has finished loading
    func enable (webviewURL: URL?,
                 shouldMigrateCookies: Bool,
                 delegates: [AnyObject]?,
                 view: UIView?,
                 completion: ((Bool, Error?) -> Void)?)

    /// Called when the module needs to disable the webview
    func disable()

    /// Internal webview status check.
    ///
    /// - Returns: Bool indicating whether or not the internal webview is ready for dispatching.
    func isWebViewReady() -> Bool

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    /// - data: [String:Any] Dictionary of preferably String or [String] values.
    /// - completion: Optional completion handler to call when call completes.
    func track(_ data: [String: Any],
               completion: ((_ success: Bool, _ info: [String: Any], _ error: Error?) -> Void)?)

    /// Handles JavaScript evaluation on the WebView instance
    ///
    /// - Parameters:
    /// - jsString: The JavaScript call to be executed in the webview
    /// - completion: Optional completion block to be called after the JavaScript call completes
    func evaluateJavascript (_ jsString: String, _ completion: (([String: Any]) -> Void)?)

    /// Adds optional delegates to the WebView instance
    ///
    /// - Parameter delegates: Array of delegates, downcast from AnyObject due to different delegate APIs for UIWebView and WKWebView. Expected to be one of UIWebViewDelegate or WKNavigationDelegate
    func setWebViewDelegates(_ delegates: [AnyObject])

    /// Removes optional delegates for the WebView instance
    ///
    /// - Parameter delegates: Array of delegates, downcast from AnyObject due to different delegate APIs for UIWebView and WKWebView. Expected to be one of UIWebViewDelegate or WKNavigationDelegate
    func removeWebViewDelegates(_ delegates: [AnyObject])

    /// Sets a root view for WKWebView to be attached to. Only required for complex view hierarchies (e.g. Push Notifications loading a view).
    ///
    /// - Parameters:
    /// - view: UIView instance for WKWebView to be attached to
    /// - completion: Optional completion to be called when webview was attached to the view
    func setRootView(_ view: UIView,
                     completion: ((_ success: Bool) -> Void)?)
}
