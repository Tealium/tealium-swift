//
//  TealiumTagManagement.swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

enum TealiumTagManagementKey {
    static let jsCommand = "js_command"
    static let jsResult = "js_result"
    static let moduleName = "tagmanagement"
    static let responseHeader = "response_headers"
    static let payload = "payload"
}

enum TealiumTagManagementConfigKey {
    static let disable = "disable_tag_management"
    static let maxQueueSize = "tagmanagement_queue_size"
    static let overrideURL = "tagmanagement_override_url"
}

enum TealiumTagManagementValue {
    static let defaultQueueSize = 100
}

enum TealiumTagManagementError: Error {
    case couldNotCreateURL
    case couldNotLoadURL
    case couldNotJSONEncodeData
    case noDataToTrack
    case webViewNotYetReady
    case unknownDispatchError
}

// MARK: 
// MARK: EXTENSIONS

public extension TealiumConfig {

    func setTagManagementQueueSize(queueSize: Int) {
        optionalData[TealiumTagManagementConfigKey.maxQueueSize] = queueSize
    }

    func setTagManagementOverrideURL(string: String) {
        optionalData[TealiumTagManagementConfigKey.overrideURL] = string
    }

}

// NOTE: UIWebview, the primary element of TealiumTagManagement can not run in XCTests.

#if TEST
#else
public extension Tealium {

    func tagManagement() -> TealiumTagManagement? {
        guard let module = modulesManager.getModule(forName: TealiumTagManagementKey.moduleName) as? TealiumTagManagementModule else {
            return nil
        }

        return module.tagManagement
    }
}
#endif

// MARK: 
// MARK: MODULE SUBCLASS

class TealiumTagManagementModule: TealiumModule {

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumTagManagementKey.moduleName,
                                   priority: 1100,
                                   build: 3,
                                   enabled: true)
    }

    #if TEST
    #else

    fileprivate weak var dispatchQueue: DispatchQueue?
    var tagManagement = TealiumTagManagement()

    override func enable(_ request: TealiumEnableRequest) {
        let config = request.config
        if config.optionalData[TealiumTagManagementConfigKey.disable] as? Bool == true {
            DispatchQueue.main.async {
                self.tagManagement.disable()
            }
            self.didFinish(request,
                           info: nil)
            return
        }

        let account = config.account
        let profile = config.profile
        let environment = config.environment
        let overrideUrl = config.optionalData[TealiumTagManagementConfigKey.overrideURL] as? String

        dispatchQueue = config.dispatchQueue()

        DispatchQueue.main.async { [weak self] in
            guard let sel = self else {
                return
            }
            sel.tagManagement.enable(forAccount: account,
                                     profile: profile,
                                     environment: environment,
                                     overrideUrl: overrideUrl,
                                     completion: { _, error in
                                         sel.dispatchQueue?.async {
                                             if let err = error {
                                                 sel.didFailToFinish(request,
                                                         error: err)
                                                 return
                                             }
                                             sel.isEnabled = true
                                             sel.didFinish(request)
                                         }
                                     })
        }
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        DispatchQueue.main.async {
            self.tagManagement.disable()
        }
        didFinish(request,
                  info: nil)
    }

    override func track(_ track: TealiumTrackRequest) {
        if isEnabled == false {
            // Ignore while disabled
            didFinishWithNoResponse(track)
            return
        }

        dispatchTrack(track)
    }

    func didFinish(_ request: TealiumRequest,
                   info: [String: Any]?) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        response.info = info
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    func didFailToFinish(_ request: TealiumRequest,
                         info: [String: Any]?,
                         error: Error) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: false,
                                             error: error)
        response.info = info
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    func dispatchTrack(_ track: TealiumTrackRequest) {
        // Dispatch to main thread since webview requires main thread.
        DispatchQueue.main.async { [weak self] in
            guard let sel = self else {
                return
            }
            // Webview has failed for some reason
            if sel.tagManagement.isWebViewReady() == false {
                sel.didFailToFinish(track,
                                    info: nil,
                                    error: TealiumTagManagementError.webViewNotYetReady)
                return
            }

            #if TEST
            #else
            sel.tagManagement.track(track.data,
                                    completion: { success, info, error in
                                        sel.dispatchQueue?.async {

                                            track.completion?(success, info, error)

                                            if error != nil {
                                                sel.didFailToFinish(track,
                                                        info: info,
                                                        error: error!)
                                                return
                                            }
                                            sel.didFinish(track,
                                                          info: info)
                                        }
                                    })
            #endif
        }
    }
    #endif
}

// MARK: 
// MARK: TAG MANAGEMENT

#if TEST
#else
import UIKit

enum TealiumTagManagementNotificationKey {
    static let urlRequestMade = "com.tealium.tagmanagement.urlrequest"
    static let jsCommandRequested = "com.tealium.tagmanagement.jscommand"
    static let jsCommand = "js"
}

/// TIQ Supported dispatch service Module. Utlizies older but simpler UIWebView vs. newer WKWebView.
public class TealiumTagManagement: NSObject {

    static let defaultUrlStringPrefix = "https://tags.tiqcdn.com/utag"

    var delegates = TealiumMulticastDelegate<UIWebViewDelegate>()
    var didWebViewFinishLoading = false
    var account: String = ""
    var profile: String = ""
    var environment: String = ""
    var urlString: String?
    var webView: UIWebView?
    var completion: ((Bool, Error?) -> Void)?

    lazy var defaultUrlString: String = {
        let urlString = "\(TealiumTagManagement.defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/mobile.html?"
        return urlString
    }()

    lazy var urlRequest: URLRequest? = {
        guard let url = URL(string: self.urlString ?? self.defaultUrlString) else {
            return nil
        }
        let request = URLRequest(url: url)
        return request
    }()

    // MARK: PUBLIC

    /// Enable webview system.
    ///
    /// - Parameters:
    ///   - forAccount: Tealium account.
    ///   - profile: Tealium profile.
    ///   - environment: Tealium environment.
    ///   - overridUrl : Optional alternate url to load utag/tealium from.
    /// - Returns: Boolean if a webview is ready to start.
    func enable(forAccount: String,
                profile: String,
                environment: String,
                overrideUrl: String?,
                completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        if self.webView != nil {
            // WebView already enabled.
            return
        }

        self.account = forAccount
        self.profile = profile
        self.environment = environment
        if let overrideUrl = overrideUrl {
            self.urlString = overrideUrl
        } else {
            self.urlString = defaultUrlString
        }

        guard let request = self.urlRequest else {
            completion?(false, TealiumTagManagementError.couldNotCreateURL)
            return
        }
        self.webView = UIWebView()
        self.webView?.delegate = self
        self.webView?.loadRequest(request)

        self.enableNotifications()

        self.completion = completion
    }

    func enableNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(processRequest),
                                               name: Notification.Name(TealiumTagManagementNotificationKey.jsCommandRequested),
                                               object: nil)
    }

    @objc
    func processRequest(sender: Notification) {
        guard let jsCommandString = sender.userInfo?[TealiumTagManagementNotificationKey.jsCommand] as? String else {
            return
        }
        // Error reporting?
        DispatchQueue.main.async {
            _ = self.webView?.stringByEvaluatingJavaScript(from: jsCommandString)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Disable the webview system.
    func disable() {
        self.webView?.stopLoading()
        self.webView = nil
    }

    func isTagManagementEnabled() -> Bool {
        return webView != nil
    }

    /// Internal webview status check.
    ///
    /// - Returns: Bool indicating whether or not the internal webview is ready for dispatching.
    func isWebViewReady() -> Bool {
        guard nil != webView else {
            return false
        }
        if didWebViewFinishLoading == false {
            return false
        }

        return true
    }

    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    ///   - data: [String:Any] Dictionary of preferrably String or [String] values.
    ///   - completion: Optional completion handler to call when call completes.
    public func track(_ data: [String: Any],
                      completion: ((_ success: Bool, _ info: [String: Any], _ error: Error?) -> Void)?) {
        var appendedData = data
        appendedData[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        let sanitizedData = TealiumTagManagementUtils.sanitized(dictionary: appendedData)
        guard let encodedPayloadString = TealiumTagManagementUtils.jsonEncode(sanitizedDictionary: sanitizedData) else {
            completion?(false,
                        ["original_payload": appendedData, "sanitized_payload": sanitizedData],
                        TealiumTagManagementError.couldNotJSONEncodeData)
            return
        }

        let legacyType = TealiumTagManagementUtils.getLegacyType(fromData: sanitizedData)
        let javascript = "utag.track(\'\(legacyType)\',\(encodedPayloadString))"

        var info = [String: Any]()
        info[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        info[TealiumTagManagementKey.jsCommand] = javascript
        info += [TealiumTagManagementKey.payload: appendedData]
        if let result = self.webView?.stringByEvaluatingJavaScript(from: javascript) {
            info += [TealiumTagManagementKey.jsResult: result]
        }

        completion?(true, info, nil)
    }

}

#if swift(>=4.2)
public typealias WebViewNavigationTypeAlias = UIWebView.NavigationType
#else
public typealias WebViewNavigationTypeAlias = UIWebViewNavigationType
#endif

extension TealiumTagManagement: UIWebViewDelegate {
    public func webView(_ webView: UIWebView,
                        shouldStartLoadWith request: URLRequest,
                        navigationType: WebViewNavigationTypeAlias) -> Bool {

        var shouldStart = true

        // Broadcast request for any listeners (Remote command module)
        // NOTE: Remote command calls are prefixed with 'tealium://'
        //  Because there is no direct link between Remote Command
        //  and Tag Management, such a call would appear as a failed call
        //  in any web console for this webview.
        let notification = Notification(name: Notification.Name(TealiumTagManagementNotificationKey.urlRequestMade),
                                        object: webView,
                                        userInfo: [TealiumTagManagementNotificationKey.urlRequestMade: request])
        NotificationCenter.default.post(notification)

        // Look for false from any delegate
        delegates.invoke {
            if $0.webView?(webView,
                    shouldStartLoadWith: request,
                    navigationType: navigationType) == false {
                shouldStart = false
            }
        }

        return shouldStart
    }

    public func webViewDidStartLoad(_ webView: UIWebView) {
        delegates.invoke {
            $0.webViewDidStartLoad?(webView)
        }
    }

    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        delegates.invoke {
            $0.webView?(webView, didFailLoadWithError: error)
        }
        if didWebViewFinishLoading == true {
            return
        }
        didWebViewFinishLoading = true
        self.completion?(false, error)
    }

    public func webViewDidFinishLoad(_ webView: UIWebView) {
        didWebViewFinishLoading = true
        delegates.invoke {
            $0.webViewDidFinishLoad?(webView)
        }

        DispatchQueue.global(qos: .background).async {

            self.completion?(true, nil)
        }
    }

}
#endif

// MARK: 
// MARK: UTILS

class TealiumTagManagementUtils {

    class func getLegacyType(fromData: [String: Any]) -> String {
        // default to link. view will always pass call_type = "view"
        var legacyType = "link"
        if let callType = fromData[TealiumKey.callType] as? String {
            legacyType = callType
        }
        return legacyType
    }

    class func jsonEncode(sanitizedDictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sanitizedDictionary,
                                                      options: [])
            let string = NSString(data: jsonData,
                                  encoding: String.Encoding.utf8.rawValue)
            return string as String?
        } catch {
            return nil
        }
    }

    class func sanitized(dictionary: [String: Any]) -> [String: Any] {
        var clean = [String: Any]()

        for (key, value) in dictionary {
            if value is String || value is [String] {
                clean[key] = value
            } else {
                let stringified = "\(value)"
                clean[key] = stringified
            }
        }

        return clean
    }

}
