//
//  TealiumTagManagementWKWebView.swift
//  tealium-swift
//
//  Created by Craig Rouse on 06/12/2018.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit
#if tagmanagement
import TealiumCore
#endif

public enum WebViewState: Int {
    case isLoaded = 0
    case isLoading = 1
    case didFailToLoad = 2
    case notYetLoaded = 3
}

public class TealiumTagManagementWKWebView: NSObject, TealiumTagManagementProtocol {

    var webview: WKWebView?
    var webviewConfig: WKWebViewConfiguration?
    var webviewDidFinishLoading = false
    var enableCompletion: ((_ success: Bool, _ error: Error?) -> Void)?
    // current view being used for WKWebView
    weak var view: UIView?
    var url: URL?
    var reloadHandler: TealiumCompletion?
    var currentState: AtomicInteger = AtomicInteger(value: WebViewState.notYetLoaded.rawValue)

    public var delegates: TealiumMulticastDelegate<WKNavigationDelegate>? = TealiumMulticastDelegate<WKNavigationDelegate>()

    /// Enables the webview. Called by the webview module at init time.
    ///
    /// - Parameters:
    ///     - webviewURL: `URL?` (typically for "mobile.html") to be loaded by the webview
    ///     - shouldMigrateCookies: `Bool` indicating whether cookies should be migrated from `HTTPCookieStore` (`UIWebView`).
    ///     - delegates: `[AnyObject]?` Array of delegates, downcast fromAnyObject to account for any future potential changes in WebView APIs
    ///     - shouldAddCookieObserver: `Bool` indicating whether the cookie observer should be added. Default `true`.
    ///     - view: `UIView? ` - required `WKWebView`, if one is not provided we attach to the window object
    ///     - completion: completion block to be called when the webview has finished loading
    public func enable(webviewURL: URL?,
                       shouldMigrateCookies: Bool,
                       delegates: [AnyObject]?,
                       shouldAddCookieObserver: Bool,
                       view: UIView?,
                       completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        guard webview == nil else {
            // webview already enabled
            return
        }
        if let delegates = delegates {
            setWebViewDelegates(delegates)
        }
        enableCompletion = completion
        self.url = webviewURL
        setupWebview(forURL: webviewURL, shouldAddCookieObserver: shouldAddCookieObserver, withSpecificView: view)
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    ///￼
    /// - Parameters:
    ///     - view: `UIView` instance for WKWebView to be attached to
    ///     - completion: Completion block to be run when the operation has completed
    public func setRootView(_ view: UIView,
                            completion: ((_ success: Bool) -> Void)?) {
        self.view = view
        // forward success/failure to optional completion
        self.attachToUIView(specificView: view) { success in
            completion?(success)
        }
    }

    /// Adds optional delegates to the WebView instance.
    ///￼
    /// - Parameter delegates: `[AnyObject]` Array of delegates, downcast from AnyObject to account for any future potential changes in WebView APIs
    public func setWebViewDelegates(_ delegates: [AnyObject]) {
        delegates.forEach { delegate in
            if let delegate = delegate as? WKNavigationDelegate {
                self.delegates?.add(delegate)
            }
        }
    }

    /// Removes optional delegates for the WebView instance.
    ///￼
    /// - Parameter delegates: `[AnyObject]` Array of delegates, downcast from AnyObject to account for any future potential changes in WebView APIs
    public func removeWebViewDelegates(_ delegates: [AnyObject]) {
        delegates.forEach { delegate in
            if let delegate = delegate as? WKNavigationDelegate {
                self.delegates?.remove(delegate)
            }
        }
    }

    /// Configures an instance of WKWebView for later use.
    ///￼
    /// - Parameters:
    ///    - url: `URL` (typically for mobile.html) to load in the webview
    ///    - specificView: `UIView?` to attach to
    func setupWebview(forURL url: URL?,
                      shouldAddCookieObserver: Bool,
                      withSpecificView specificView: UIView?) {
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
               return
            }
            // required to force cookies to sync
            if #available(iOS 11, *), shouldAddCookieObserver {
                WKWebsiteDataStore.default().httpCookieStore.add(self)
            }
            let config = WKWebViewConfiguration()
            self.webview = WKWebView(frame: .zero, configuration: config)
            self.webview?.navigationDelegate = self
            guard let webview = self.webview else {
                self.enableCompletion?(false, TealiumWebviewError.webviewNotInitialized)
                return
            }

            // attach the webview to the view before continuing
            self.attachToUIView(specificView: specificView) { _ in
                self.migrateCookies(forWebView: webview) {
                    guard let url = url else {
                        self.enableCompletion?(false, TealiumWebviewError.webviewURLMissing)
                        return
                    }
                    let request = URLRequest(url: url)
                    TealiumQueues.mainQueue.async {
                        webview.load(request)
                    }
                }
            }
        }
    }

    /// Reloads the webview.
    ///
    /// - Parameter completion: Completion block to be run when the webview has finished reloading
    public func reload(_ completion: @escaping (Bool, [String: Any]?, Error?) -> Void) {
        guard let url = url else {
            return
        }
        reloadHandler = completion
        let request = URLRequest(url: url)
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
               return
            }
            self.currentState = AtomicInteger(value: WebViewState.isLoading.rawValue)
            self.webview?.load(request)
        }
    }

    /// Internal webview status check.
    ///
    /// - Returns: `Bool` indicating whether or not the internal webview is ready for dispatching.
    public func isWebViewReady() -> Bool {
        guard webview != nil else {
            return false
        }
        return WebViewState(rawValue: currentState.value) == WebViewState.isLoaded
    }

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    ///     - data: `[String: Any]` representing a track request
    ///     - completion: Optional completion handler to call when call completes.
    public func track(_ data: [String: Any],
                      completion: ((Bool, [String: Any], Error?) -> Void)?) {
        guard let javascriptString = data.tealiumJavaScriptTrackCall else {
            completion?(false,
                        ["original_payload": data, "sanitized_payload": data],
                        TealiumTagManagementError.couldNotJSONEncodeData)
            return
        }
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            // always re-attach to UIView. If specific view has been previously passed in, this will be used.
            // nil is passed to force attachToUIView to auto-detect and check for a valid view, since this track call could be happening after the view was dismissed
            self.attachToUIView(specificView: nil) { _ in }
        }

        var info = [String: Any]()
        info[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        info[TealiumTagManagementKey.jsCommand] = javascriptString
        info += [TealiumTagManagementKey.payload: data]
        self.evaluateJavascript(javascriptString) { result in
            info += result
            completion?(true, info, nil)
        }
    }

    /// Processes a batch of track requests.
    ///
    /// - Parameters:
    ///     - data: `[[String: Any]]` of requests
    ///     - completion: Optional completion handler to call when call completes.
    public func trackMultiple(_ data: [[String: Any]],
                              completion: ((Bool, [String: Any], Error?) -> Void)?) {

        let totalSuccesses = AtomicInteger(value: 0)

        data.forEach {
            self.track($0) { success, _, _ in
                if success {
                    _ = totalSuccesses.incrementAndGet()
                } else {
                    _ = totalSuccesses.decrementAndGet()
                }
            }
        }

        let allCallsSuccessful = totalSuccesses.value == data.count

        completion?(allCallsSuccessful, ["": ""], nil)

    }

    /// Handles JavaScript evaluation on the WKWebView instance.
    ///
    /// - Parameters:
    ///     - jsString: `String` containing the JavaScript call to be executed in the webview
    ///     - completion: Optional completion block to be called after the JavaScript call completes
    public func evaluateJavascript (_ jsString: String, _ completion: (([String: Any]) -> Void)?) {
        // webview js evaluation must be on main thread
        TealiumQueues.mainQueue.async { [weak self] in
            guard let self = self else {
               return
            }
            if self.webview?.superview == nil {
                self.attachToUIView(specificView: nil) { _ in }
            }
            self.webview?.evaluateJavaScript(jsString) { result, error in
                let info = Atomic(value: [String: Any]())
                if let result = result {
                    info.value += [TealiumTagManagementKey.jsResult: result]
                }

                if let error = error {
                    info.value += [TealiumTagManagementKey.jsError: error]
                }
                TealiumQueues.backgroundConcurrentQueue.write {
                    completion?(info.value)
                }
            }
        }
    }

    /// Called by the WKWebView delegate when the page finishes loading.
    ///￼
    /// - Parameters:
    ///     - state: `TealiumWebViewState` -  The webview state after the state change
    ///     - error: `Error?`
    public func webviewStateDidChange(_ state: TealiumWebViewState,
                                      withError error: Error?) {
        switch state {
        case .loadSuccess:
            self.currentState = AtomicInteger(value: WebViewState.isLoaded.rawValue)
            if let reloadHandler = self.reloadHandler {
                self.webviewDidFinishLoading = true
                reloadHandler(true, nil, nil)
                self.reloadHandler = nil
            } else {
                guard webviewDidFinishLoading == false else {
                    return
                }
                webviewDidFinishLoading = true

                if let enableCompletion = enableCompletion {
                    self.enableCompletion = nil
                    enableCompletion(true, nil)
                }

            }
        case .loadFailure:
            self.currentState = AtomicInteger(value: WebViewState.didFailToLoad.rawValue)
            if let reloadHandler = self.reloadHandler {
                self.webviewDidFinishLoading = true
                reloadHandler(false, nil, error)
                self.reloadHandler = nil
            } else {
                self.enableCompletion?(false, error)
            }
        }
    }

    /// Called when the module needs to disable the webview.
      public func disable() {
          self.delegates = nil
          // these methods MUST be called on the main thread. Cannot be async, or self will be deallocated before these run
          if !Thread.isMainThread {
              TealiumQueues.mainQueue.sync {
                self.webview?.navigationDelegate = nil
                // if this isn't run, the webview will remain attached in a kind of zombie state
                self.webview?.removeFromSuperview()
                self.webview?.stopLoading()
              }
          } else {
              self.webview?.navigationDelegate = nil
              // if this isn't run, the webview will remain attached in a kind of zombie state
              self.webview?.removeFromSuperview()
              self.webview?.stopLoading()
          }
          self.webview = nil
      }

      deinit {
          self.disable()
      }
}
