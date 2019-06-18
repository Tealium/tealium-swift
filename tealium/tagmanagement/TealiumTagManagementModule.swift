//
//  TealiumTagManagementModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if tagmanagement
import TealiumCore
#endif

// MARK: MODULE SUBCLASS
public class TealiumTagManagementModule: TealiumModule {
    var tagManagement: TealiumTagManagementProtocol?
    var remoteCommandResponseObserver: NSObjectProtocol?

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumTagManagementKey.moduleName,
                                   priority: 1100,
                                   build: 3,
                                   enabled: true)
    }

    // NOTE: UIWebview, the primary element of TealiumTagManagement cannot run in XCTests.
    #if TEST
    #else

    /// Enables the module and sets up the webview instance
    ///
    /// - Parameter request: TealiumEnableRequest - the request from the core library to enable this module
    override public func enable(_ request: TealiumEnableRequest) {
        if request.config.getShouldUseLegacyWebview() == true {
            self.tagManagement = TealiumTagManagementUIWebView()
        } else if #available(iOS 11.0, *) {
            self.tagManagement = TealiumTagManagementWKWebView()
        } else {
            self.tagManagement = TealiumTagManagementUIWebView()
        }

        let config = request.config
        enableNotifications()
        if config.optionalData[TealiumTagManagementConfigKey.disable] as? Bool == true {
            DispatchQueue.main.async {
                self.tagManagement?.disable()
            }
            self.didFinish(request,
                           info: nil)
            return
        }

        DispatchQueue.main.async {
            let config = request.config
            self.tagManagement?.enable(webviewURL: config.webviewURL(), shouldMigrateCookies: true, delegates: config.getWebViewDelegates(), view: config.getRootView()) { _, error in
                                          DispatchQueue.main.async {
                                             if let err = error {
                                                 self.didFailToFinish(request,
                                                                      error: err)
                                                 return
                                             }
                                             self.isEnabled = true
                                             self.didFinish(request)
                                          }
            }
        }
    }

    /// Listens for notifications from the Remote Commands module. Typically these will be responses from a Remote Command that has finished executing.
    func enableNotifications() {
        remoteCommandResponseObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(TealiumKey.jsNotificationName), object: nil, queue: OperationQueue.main) { notification in
            if let userInfo = notification.userInfo, let jsCommand = userInfo[TealiumKey.jsCommand] as? String {
                // Webview instance will ensure this is processed on the main thread
                self.tagManagement?.evaluateJavascript(jsCommand, nil)
            }
        }
    }

    /// Disables the Tag Management module
    ///
    /// - Parameter request: TealiumDisableRequest indicating that the module should be disabled
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        DispatchQueue.main.async {
            self.tagManagement?.disable()
        }
        didFinish(request,
                  info: nil)
    }

    /// Handles the track request and forwards to the webview for processing
    ///
    /// - Parameter track: TealiumTrackRequest to be evaluated
    override public func track(_ track: TealiumTrackRequest) {
        if isEnabled == false {
            // Ignore while disabled
            didFinishWithNoResponse(track)
            return
        }
        var newTrackData = track.data
        newTrackData[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        let newTrack = TealiumTrackRequest(data: newTrackData, completion: track.completion)
        dispatchTrack(newTrack)
    }

    /// Called when the module has finished processing the request
    ///
    /// - Parameters:
    /// - request: TealiumRequest that the module has finished processing
    /// - info: [String: Any]? optional dictionary containing additional information from the module about how it handled the request
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

    /// Called when the module has failed to process the request
    ///
    /// - Parameters:
    /// - request: TealiumRequest that the module has failed to process
    /// - info: [String: Any]? optional dictionary containing additional information from the module about how it handled the request
    /// - error: Error reason
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

    /// Sends the track request to the webview
    ///
    /// - Parameter track: TealiumTrackRequest to be sent to the webview
    func dispatchTrack(_ track: TealiumTrackRequest) {
        // Dispatch to main thread since webview requires main thread.
        DispatchQueue.main.async {
            // Webview has failed for some reason
            if self.tagManagement?.isWebViewReady() == false {
                self.didFailToFinish(track,
                                     info: nil,
                                     error: TealiumTagManagementError.webViewNotYetReady)
                return
            }

            #if TEST
            #else
            self.tagManagement?.track(track.data) { success, info, error in
                                        DispatchQueue.main.async {
                                            track.completion?(success, info, error)

                                            if error != nil {
                                                self.didFailToFinish(track,
                                                                     info: info,
                                                                     error: error!)
                                                return
                                            }
                                            self.didFinish(track,
                                                           info: info)
                                        }
            }
            #endif
        }
    }
    #endif
}
