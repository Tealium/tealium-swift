//
//  TagManagementWKWebView.swift
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

enum InternalWebViewState: Int {
    case isLoaded = 0
    case isLoading = 1
    case didFailToLoad = 2
    case notYetLoaded = 3
}

typealias TrackCompletion = ((Bool, [String: Any], Error?) -> Void)

class TagManagementWKWebView: NSObject, TagManagementProtocol, LoggingDataToStringConverter {

    private let onWebView = TealiumReplaySubject<WKWebView>()
    var webview: WKWebView? {
        get {
            onWebView.last()
        }
        set {
            if let newValue = newValue {
                onWebView.publish(newValue)
            } else {
                onWebView.clear()
            }
        }
    }
    var tealConfig: TealiumConfig
    var enableCompletion: ((_ success: Bool, _ error: Error?) -> Void)?
    // current view being used for WKWebView
    weak var view: UIView?
    var url: URL?
    var reloadHandler: TealiumCompletion?
    var currentState = InternalWebViewState.notYetLoaded
    weak var moduleDelegate: ModuleDelegate?

    var delegates: TealiumMulticastDelegate<WKNavigationDelegate>? = TealiumMulticastDelegate<WKNavigationDelegate>()
    var logger: TealiumLoggerProtocol? {
        return tealConfig.logger
    }
    init(config: TealiumConfig, delegate: ModuleDelegate?) {
        moduleDelegate = delegate
        tealConfig = config
    }

    /// Enables the webview. Called by the webview module at init time.
    ///
    /// - Parameters:
    ///     - webviewURL: `URL?` (typically for "mobile.html") to be loaded by the webview
    ///     - delegates: `[WKNavigationDelegate]?` Array of delegates
    ///     - view: `UIView? ` - required `WKWebView`, if one is not provided we attach to the window object
    ///     - completion: completion block to be called when the webview has finished loading
    func enable(webviewURL: URL?,
                delegates: [WKNavigationDelegate]?,
                view: UIView?,
                completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        guard webview == nil else {
            // webview already enabled
            return
        }
        if let delegates = delegates {
            setWebViewDelegates(delegates)
        }
        if let completion = completion {
            enableCompletion = { success, error in
                TealiumQueues.backgroundSerialQueue.async {
                    completion(success, error)
                }
            }
        }
        self.url = webviewURL
        setupWebview(forURL: webviewURL, withSpecificView: view)
    }

    /// Sets a root view for `WKWebView` to be attached to. Only required for complex view hierarchies.
    /// ￼
    /// - Parameters:
    ///     - view: `UIView` instance for WKWebView to be attached to
    /// - returns: a success `Bool`, true if the webview was successfully attached
    @discardableResult
    func setRootView(_ view: UIView) -> Bool {
        self.view = view
        // forward success/failure to optional completion
        return self.attachToUIView(specificView: view)
    }

    /// Adds optional delegates to the WebView instance.
    /// ￼
    /// - Parameter delegates: `[WKNavigationDelegate]` Array of delegates
    func setWebViewDelegates(_ delegates: [WKNavigationDelegate]) {
        delegates.forEach {
            self.delegates?.add($0)
        }
    }

    /// Removes optional delegates for the WebView instance.
    /// ￼
    /// - Parameter delegates: `[WKNavigationDelegate]` Array of delegates
    func removeWebViewDelegates(_ delegates: [WKNavigationDelegate]) {
        delegates.forEach {
            self.delegates?.remove($0)
        }
    }

    /// Configures an instance of WKWebView for later use.
    /// ￼
    /// - Parameters:
    ///    - url: `URL` (typically for mobile.html) to load in the webview
    ///    - specificView: `UIView?` to attach to
    func setupWebview(forURL url: URL?,
                      withSpecificView specificView: UIView?) {
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            let config = self.tealConfig.webviewConfig
            if let processPool = self.tealConfig.webviewProcessPool {
                config.processPool = processPool
            }
            self.webview = WKWebView(frame: .zero, configuration: config)
            self.webview?.navigationDelegate = self
            guard let webview = self.webview else {
                self.enableCompletion?(false, WebviewError.webviewNotInitialized)
                return
            }
            // attach the webview to the view before continuing
            self.attachToUIView(specificView: specificView)
            guard let url = url else {
                self.enableCompletion?(false, WebviewError.webviewURLMissing)
                return
            }
            let request = URLRequest(url: url)
            webview.load(request)
        }
    }

    /// Reloads the webview.
    ///
    /// - Parameter completion: Completion block to be run when the webview has finished reloading
    func reload(_ completion: @escaping (Bool, [String: Any]?, Error?) -> Void) {
        guard let url = url else {
            return
        }
        let request = URLRequest(url: url)
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            if let oldHandler = self.reloadHandler {
                self.reloadHandler = { success, info, error in
                    oldHandler(success, info, error)
                    completion(success, info, error)
                }
            } else {
                self.reloadHandler = completion
                self.currentState = .isLoading
                self.webview?.load(request)
            }
        }
    }

    /// Internal webview status check.
    ///
    /// - Returns: `Bool` indicating whether or not the internal webview is ready for dispatching.
    var isWebViewReady: Bool {
        guard webview != nil else {
            return false
        }
        return currentState == InternalWebViewState.isLoaded
    }

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    ///     - data: `[String: Any]` representing a track request
    ///     - completion: Optional completion handler to call when call completes.
    func track(_ data: [String: Any],
               completion: TrackCompletion?) {
        guard let javascriptString = convertData(data, toStringWith: { try $0.tealiumJavaScriptTrackCall() }) else {
            completion?(false,
                        ["original_payload": data, "sanitized_payload": data],
                        TagManagementError.couldNotJSONEncodeData)
            return
        }
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            // always re-attach to UIView. If specific view has been previously passed in, this will be used.
            // nil is passed to force attachToUIView to auto-detect and check for a valid view, since this track call could be happening after the view was dismissed
            self.attachToUIView(specificView: nil)
        }

        var info = [String: Any]()
        info[TealiumDataKey.dispatchService] = TagManagementKey.moduleName
        info[TealiumDataKey.jsCommand] = javascriptString
        info += [TealiumDataKey.payload: data]
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
    func trackMultiple(_ data: [[String: Any]],
                       completion: TrackCompletion?) {
        let group = DispatchGroup()
        var anyError: Error?
        data.forEach { _ in group.enter() } // Needs to enter every block before any track is started or we risk leaving before the others have entered (cause errors are sync) and therefore notifying
        group.notify(queue: TealiumQueues.backgroundSerialQueue) {
            completion?(anyError == nil, [String: Any](), anyError)
        }
        data.forEach {
            self.track($0) { _, _, error in
                if anyError == nil {
                    anyError = error
                }
                group.leave()
            }
        }
    }

    /// Handles JavaScript evaluation on the WKWebView instance.
    ///
    /// - Parameters:
    ///     - jsString: `String` containing the JavaScript call to be executed in the webview
    ///     - completion: Optional completion block to be called after the JavaScript call completes
    func evaluateJavascript (_ jsString: String, _ completion: (([String: Any]) -> Void)?) {
        // webview js evaluation must be on main thread
        TealiumQueues.secureMainThreadExecution { [weak self] in
            guard let self = self else {
                return
            }
            if self.webview?.superview == nil {
                self.attachToUIView(specificView: nil)
            }
            self.webview?.evaluateJavaScript(jsString) { result, error in
                var info = [String: Any]()
                if let result = result {
                    info += [TealiumDataKey.jsResult: result]
                }

                if let error = error {
                    info += [TealiumDataKey.jsError: error]
                }
                TealiumQueues.backgroundSerialQueue.async {
                    completion?(info)
                }
            }
        }
    }

    /// Called by the WKWebView delegate when the page finishes loading.
    /// ￼
    /// - Parameters:
    ///     - state: `WebViewState` -  The webview state after the state change
    ///     - error: `Error?`
    func webviewStateDidChange(_ state: WebViewState,
                               withError error: Error?) {
        let success = state == .loadSuccess
        self.currentState = success ? .isLoaded : .didFailToLoad
        let finalError = success ? nil : error

        if let enableCompletion = enableCompletion {
            self.enableCompletion = nil
            enableCompletion(success, finalError)
        }
        if let reloadHandler = self.reloadHandler {
            self.reloadHandler = nil
            TealiumQueues.backgroundSerialQueue.async {
                reloadHandler(success, nil, finalError)
            }
        }
    }

    /// Called when the module needs to disable the webview.
    func disable() {
        self.delegates = nil
        // these method MUST be called on the main thread. If async, self will be deallocated before this runs, so we capture the webview instead
        guard let webview = self.webview else {
            return
        }
        TealiumQueues.secureMainThreadExecution {
            webview.navigationDelegate = nil
            // if this isn't run, the webview will remain attached in a kind of zombie state
            webview.removeFromSuperview()
            webview.stopLoading()
        }
        self.webview = nil
    }

    func getWebView(_ completion: @escaping (WKWebView) -> Void) {
        TealiumQueues.secureMainThreadExecution {
            self.onWebView.subscribeOnce(completion)
        }
    }

    deinit {
        self.disable()
    }
}
#endif
