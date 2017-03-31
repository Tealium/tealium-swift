//
//  TealiumTagManagement.swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

import UIKit

///// Internal Module delegate
protocol TealiumTagManagementDelegate : class {
    func tagManagementWebViewFinishedLoading()
}

enum TealiumTagManagementNotificationKey {
    static let urlRequestMade = "com.tealium.tagmanagement.urlrequest"
}

/// TIQ Supported dispatch service Module. Utlizies older but simpler UIWebView vs. newer WKWebView.  
public class TealiumTagManagement : NSObject {
    
    static let defaultUrlStringPrefix = "https://tags.tiqcdn.com/utag"

    var delegates = TealiumMulticastDelegate<UIWebViewDelegate>()
    var didWebViewFinishLoading = false
    var account : String = ""
    var profile : String = ""
    var environment : String = ""
    var urlString : String?
    var webView : UIWebView?
    var completion : ((Bool, Error?)->Void)?
    lazy var defaultUrlString : String = {
        let urlString = "\(defaultUrlStringPrefix)/\(self.account)/\(self.profile)/\(self.environment)/mobile.html?"
        return urlString
    }()
    lazy var urlRequest : URLRequest? = {
        guard let url = URL(string: self.urlString ?? self.defaultUrlString) else {
            return nil
        }
        let request = URLRequest(url: url)
        return request
    }()
    weak var internalDelegate : TealiumTagManagementDelegate?

    
    // MARK: PUBLIC
    
    /// Enable webview system.
    ///
    /// - Parameters:
    ///   - forAccount: Tealium account.
    ///   - profile: Tealium profile.
    ///   - environment: Tealium environment.
    /// - Returns: Boolean if a webview is ready to start.
    func enable(forAccount: String,
                profile: String,
                environment: String,
                completion: ((_ success:Bool, _ error: Error?)-> Void)?) {
        

        if self.webView != nil {
            // WebView already enabled.
            return
        }
        
        self.account = forAccount
        self.profile = profile
        self.environment = environment
        
        guard let request = self.urlRequest else {
            completion?(false, TealiumTagManagementError.couldNotCreateURL)
            return
        }
        self.webView = UIWebView()
        self.webView?.delegate = self
        self.webView?.loadRequest(request)
        
        self.completion = completion

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
        
        if self.webView == nil { return false }
        if self.webView!.isLoading == true { return false }
        if didWebViewFinishLoading == false { return false }
        
        return true
    }
    
    /// Process event data for UTAG delivery.
    ///
    /// - Parameters:
    ///   - data: [String:Any] Dictionary of preferrably String or [String] values.
    ///   - completion: Optional completion handler to call when call completes.
    func track(_ data: [String:Any],
               completion: ((_ success:Bool, _ info: [String:Any], _ error: Error?)->Void)?) {
    
        var appendedData = data
        appendedData[TealiumTagManagementKey.dispatchService] = TealiumTagManagementKey.moduleName
        
        let sanitizedData = TealiumTagManagementUtils.sanitized(dictionary: appendedData)
        guard let encodedPayloadString = TealiumTagManagementUtils.jsonEncode(sanitizedDictionary: sanitizedData) else {
            completion?(false,
                        ["original_payload":data, "sanitized_payload":sanitizedData],
                        TealiumTagManagementError.couldNotJSONEncodeData)
            return
        }
    
        let legacyType = TealiumTagManagementUtils.getLegacyType(fromData: sanitizedData)
        let javascript = "utag.track(\'\(legacyType)\',\(encodedPayloadString))"
        
        var info = [String:Any]()
        info[TealiumTagManagementKey.dispatchService] = TealiumTagManagementKey.moduleName
        info[TealiumTagManagementKey.jsCommand] = javascript
        info += [TealiumTagManagementKey.payload : data]
        if let result = self.webView?.stringByEvaluatingJavaScript(from: javascript) {
            info += [TealiumTagManagementKey.jsResult : result]
        }

        // TODO: These track calls are NOT appearing 
        completion?(true, info, nil)
        
    }
    
}

extension TealiumTagManagement : UIWebViewDelegate {
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        var shouldStart = true
        
        // Broadcast request for any listeners (Remote command module)
        let notification = Notification(name: Notification.Name.init(TealiumTagManagementNotificationKey.urlRequestMade),
                                        object: webView,
                                        userInfo: [TealiumTagManagementNotificationKey.urlRequestMade:request])
        NotificationCenter.default.post(notification)
        
        // Look for false from any delegate
        delegates.invoke{ if $0.webView?(webView,
                                         shouldStartLoadWith: request,
                                         navigationType: navigationType) == false {
                shouldStart = false
            }
        }
        
        return shouldStart
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
        
        delegates.invoke{ $0.webViewDidStartLoad?(webView) }
        
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        
        delegates.invoke{ $0.webView?(webView, didFailLoadWithError: error)}
        if didWebViewFinishLoading == true {
            return
        }
        didWebViewFinishLoading = true
        self.completion?(false, error)
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        
        didWebViewFinishLoading = true
        internalDelegate?.tagManagementWebViewFinishedLoading()
        delegates.invoke{ $0.webViewDidFinishLoad?(webView) }
        self.completion?(true, nil)
    }
    
}
