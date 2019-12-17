//
//  TealiumTagManagementProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/8/2018
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
#if tagmanagement
import TealiumCore
#endif

public protocol TealiumTagManagementProtocol {

    /// Enables the webview. Called by the webview module at init time.
    ///
    /// - Parameters:
    ///     - webviewURL: `URL?` (typically for "mobile.html") to be loaded by the webview
    ///     - shouldMigrateCookies: `Bool` indicating whether cookies should be migrated from `HTTPCookieStore` (`UIWebView`).
    ///     - delegates: `[AnyObject]?` Array of delegates, downcast from AnyObject to account for any future potential changes in WebView APIs
    ///     - shouldAddCookieObserver: `Bool` indicating whether the cookie observer should be added. Default `true`.
    ///     - view: `UIView? `- required `WKWebView`, if one is not provided we attach to the window object
    ///     - completion: completion block to be called when the webview has finished loading
    func enable (webviewURL: URL?,
                 shouldMigrateCookies: Bool,
                 delegates: [AnyObject]?,
                 shouldAddCookieObserver: Bool,
                 view: UIView?,
                 completion: ((Bool, Error?) -> Void)?)

    /// Called when the module needs to disable the webview.
    func disable()

    /// Internal webview status check.
    ///
    /// - Returns: `Bool` indicating whether or not the internal webview is ready for dispatching.
    func isWebViewReady() -> Bool

    /// Reloads the webview
    ///
    /// - Parameter completion: Completion block to be run when the webview has finished reloading
    func reload(_ completion: @escaping TealiumCompletion)

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    ///     - data: `[String: Any]` representing a track request
    ///     - completion: Optional completion handler to call when call completes.
    func track(_ data: [String: Any],
               completion: ((_ success: Bool, _ info: [String: Any], _ error: Error?) -> Void)?)

    /// Processes a batch of track requests
    ///
    /// - Parameters:
    ///     - data: `[[String: Any]]` of requests
    ///     - completion: Optional completion handler to call when call completes.
    func trackMultiple(_ data: [[String: Any]],
                       completion: ((Bool, [String: Any], Error?) -> Void)?)

    /// Handles JavaScript evaluation on the WKWebView instance
    ///
    /// - Parameters:
    ///     - jsString: `String` containing the JavaScript call to be executed in the webview
    ///     - completion: Optional completion block to be called after the JavaScript call completes
    func evaluateJavascript (_ jsString: String, _ completion: (([String: Any]) -> Void)?)

    /// Adds optional delegates to the WebView instance.
    ///￼
    /// - Parameter delegates: `[AnyObject]` Array of delegates, downcast from AAnyObject to account for any future potential changes in WebView APIs
    func setWebViewDelegates(_ delegates: [AnyObject])

    /// Removes optional delegates for the WebView instance.
    ///￼
    /// - Parameter delegates: `[AnyObject]` Array of delegates, downcast from AnyObject to account for any future potential changes in WebView APIs
    func removeWebViewDelegates(_ delegates: [AnyObject])

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameters:
    ///     - view: `UIView` instance for WKWebView to be attached to
    ///     - completion: Completion block to be run when the operation has completed
    func setRootView(_ view: UIView,
                     completion: ((_ success: Bool) -> Void)?)

}
