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

public class TealiumTagManagementModule: TealiumModule {
    var tagManagement: TealiumTagManagementProtocol?
    var remoteCommandResponseObserver: NSObjectProtocol?
    var errorState = AtomicInteger()
    var pendingTrackRequests = [TealiumRequest]()

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumTagManagementKey.moduleName,
                                   priority: 1100,
                                   build: 3,
                                   enabled: true)
    }

    // NOTE: UIWebview cannot run in XCTests.
    #if TEST
    #else

    override public func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            dynamicTrack(request)
        case let request as TealiumBatchTrackRequest:
            dynamicTrack(request)
        case let request as TealiumRemoteAPIRequest:
            dynamicTrack(request)
        default:
            didFinish(request)
        }
    }

    /// Enables the module and sets up the webview instance.
    ///￼
    /// - Parameter request: `TealiumEnableRequest` - the request from the core library to enable this module
    override public func enable(_ request: TealiumEnableRequest) {
        self.tagManagement = TealiumTagManagementWKWebView()

        let config = request.config
        enableNotifications()

        self.tagManagement?.enable(webviewURL: config.webviewURL(), shouldMigrateCookies: true, delegates: config.getWebViewDelegates(), shouldAddCookieObserver: config.shouldAddCookieObserver, view: config.getRootView()) { [weak self] _, error in
            guard let self = self else {
                return
            }
            TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                guard let self = self else {
                    return
                }
                if let error = error {
                    let logger = TealiumLogger(loggerId: TealiumTagManagementModule.moduleConfig().name, logLevel: request.config.getLogLevel())
                    logger.log(message: (error.localizedDescription), logLevel: .warnings)
                    self.errorState.incrementAndGet()
                }
            }
        }
        self.isEnabled = true
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            self.didFinish(request)
        }
    }

    /// Listens for notifications from the Remote Commands module. Typically these will be responses from a Remote Command that has finished executing.
    func enableNotifications() {
        remoteCommandResponseObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(TealiumKey.jsNotificationName), object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let self = self else {
                return
            }
            if let userInfo = notification.userInfo, let jsCommand = userInfo[TealiumKey.jsCommand] as? String {
                // Webview instance will ensure this is processed on the main thread
                self.tagManagement?.evaluateJavascript(jsCommand, nil)
            }
        }
    }

    /// Adds dispatch service key to the dispatch.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        newTrack[TealiumKey.dispatchService] = TealiumTagManagementKey.moduleName
        var newRequest = TealiumTrackRequest(data: newTrack, completion: request.completion)
        newRequest.moduleResponses = request.moduleResponses
        return newRequest
    }

    /// Detects track type and dispatches appropriately.
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    func dynamicTrack(_ track: TealiumRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(track)
            return
        }

        if self.errorState.value > 0 {
            self.tagManagement?.reload { success, _, _ in
                if success {
                    self.errorState.value = 0
                    self.dynamicTrack(track)
                } else {
                    _ = self.errorState.incrementAndGet()
                    self.enqueue(track)
                    let reportRequest = TealiumReportRequest(message: "WebView load failed. Will retry.")
                    self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
                }
            }
            return
        }

        let pending = self.pendingTrackRequests
        self.pendingTrackRequests = []
        pending.forEach {
            self.dynamicTrack($0)
        }

        switch track {
        case let track as TealiumTrackRequest:
            self.dispatchTrack(prepareForDispatch(track))
        case let track as TealiumBatchTrackRequest:
            var newRequest = TealiumBatchTrackRequest(trackRequests: track.trackRequests.map { prepareForDispatch($0) },
                                                      completion: track.completion)
            newRequest.moduleResponses = track.moduleResponses
            self.dispatchTrack(newRequest)
        case let track as TealiumRemoteAPIRequest:
            self.dispatchTrack(prepareForDispatch(track.trackRequest))
            let reportRequest = TealiumReportRequest(message: "Processing remote_api request.")
            self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
            return
        default:
            self.didFinishWithNoResponse(track)
            return
        }
    }

    /// Enqueues a request for later dispatch if the webview isn't ready.
    ///
    /// - Parameter request: `TealiumRequest` to be enqueued
    func enqueue(_ request: TealiumRequest) {
        guard request is TealiumTrackRequest || request is TealiumBatchTrackRequest else {
            return
        }

        switch request {
        case let request as TealiumBatchTrackRequest:
            var requests = request.trackRequests
            requests = requests.map {
                var trackData = $0.trackDictionary, track = $0
                trackData[TealiumKey.wasQueued] = true
                trackData[TealiumKey.queueReason] = "Tag Management Webview Not Ready"
                track.data = trackData.encodable
                return track
            }
            self.pendingTrackRequests.append(TealiumBatchTrackRequest(trackRequests: requests, completion: request.completion))
        case let request as TealiumTrackRequest:
            var track = request
            var trackData = track.trackDictionary
            trackData[TealiumKey.wasQueued] = true
            trackData[TealiumKey.queueReason] = "Tag Management Webview Not Ready"
            track.data = trackData.encodable
            self.pendingTrackRequests.append(track)
        default:
            return
        }
    }

    /// Sends the track request to the webview.
    ///￼
    /// - Parameter track: `TealiumTrackRequest` to be sent to the webview
    func dispatchTrack(_ request: TealiumRequest) {
        // Webview has failed for some reason
        if tagManagement?.isWebViewReady() == false {
            TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                guard let self = self else {
                    return
                }
                self.didFailToFinish(request,
                                     info: nil,
                                     error: TealiumTagManagementError.webViewNotYetReady)
            }
            return
        }
        switch request {
        case let track as TealiumBatchTrackRequest:
                let allTrackData = track.trackRequests.map {
                    $0.trackDictionary
                }

                #if TEST
                #else
                self.tagManagement?.trackMultiple(allTrackData) { success, info, error in
                    TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                        guard let self = self else {
                            return
                        }
                        track.completion?(success, info, error)
                        guard error == nil else {
                            self.didFailToFinish(track, info: info, error: error!)
                            return
                        }
                        self.didFinish(track,
                                       info: info)
                    }
                }
                #endif
        case let track as TealiumTrackRequest:
                #if TEST
                #else
                self.tagManagement?.track(track.trackDictionary) { success, info, error in
                    TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
                        guard let self = self else {
                            return
                        }
                        track.completion?(success, info, error)
                        guard error == nil else {
                            self.didFailToFinish(track, info: info, error: error!)
                            return
                        }
                        self.didFinish(track,
                                       info: info)
                    }
                }
                #endif
        default:
            let reportRequest = TealiumReportRequest(message: "Unexpected request type received. Will not process.")
            self.delegate?.tealiumModuleRequests(module: self, process: reportRequest)
            return
        }
    }
    #endif

    /// Called when the module has finished processing the request.
    ///
    /// - Parameters:
    ///     - request: `TealiumRequest` that the module has finished processing
    ///     - info: `[String: Any]?`  containing additional information from the module about how it handled the request
    func didFinish(_ request: TealiumRequest,
                   info: [String: Any]?) {
        // No didFinish call for remote api requests
        guard request as? TealiumRemoteAPIRequest == nil else {
            return
        }
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        response.info = info
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    /// Called when the module has failed to process the request.
    ///
    /// - Parameters:
    ///     - request: `TealiumRequest` that the module has failed to process
    ///     - info: `[String: Any]?` containing additional information from the module about how it handled the request
    ///     - error: `Error`
    func didFailToFinish(_ request: TealiumRequest,
                         info: [String: Any]?,
                         error: Error) {
        // No didFinish call for remote api requests
        guard request as? TealiumRemoteAPIRequest == nil else {
            return
        }
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: false,
                                             error: error)
        response.info = info
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    /// Disables the Tag Management module.
    ///￼
    /// - Parameter request: `TealiumDisableRequest` indicating that the module should be disabled
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        self.remoteCommandResponseObserver = nil
        self.pendingTrackRequests = [TealiumRequest]()
        if !Thread.isMainThread {
            TealiumQueues.mainQueue.sync {
                self.tagManagement = nil
            }
        } else {
            self.tagManagement = nil
        }
    }

    deinit {
        self.disable(TealiumDisableRequest())
    }
}
