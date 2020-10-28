//
//  TagManagementModule.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if tagmanagement
import TealiumCore
#endif

/// Dispatch Service Module for sending track data to the Tealium Webview.
public class TagManagementModule: Dispatcher {

    public let id: String = ModuleNames.tagmanagement
    public var config: TealiumConfig
    var errorState = AtomicInteger(value: 0)
    var pendingTrackRequests = [(TealiumRequest, ModuleCompletion?)]()
    var tagManagement: TagManagementProtocol?
    var webViewState: Atomic<WebViewState>?
    weak var delegate: ModuleDelegate?

    /// Provided for unit testing￼.
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter tagManagement: Class instance conforming to `TealiumTagManagementProtocol`
    convenience init(config: TealiumConfig,
                     delegate: ModuleDelegate,
                     tagManagement: TagManagementProtocol) {
        self.init(config: config, delegate: delegate) { _ in
        }
        self.tagManagement = tagManagement
    }

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion?` block to be called when init is finished
    public required init(config: TealiumConfig,
                         delegate: ModuleDelegate,
                         completion: ModuleCompletion?) {
        self.config = config
        self.delegate = delegate
        self.tagManagement = tagManagement ?? TagManagementWKWebView(config: config, delegate: delegate)
        self.tagManagement?.enable(webviewURL: config.webviewURL,
                                   delegates: config.webViewDelegates,
                                   shouldAddCookieObserver: config.shouldAddCookieObserver,
                                   view: config.rootView) { [weak self] _, error in
            guard let self = self else {
                return
            }
            TealiumQueues.backgroundConcurrentQueue.write {
                if error != nil {
                    self.errorState.incrementAndGet()
                    self.webViewState?.value = .loadFailure
                    completion?((.failure(TagManagementError.webViewNotYetReady), nil))
                } else {
                    self.errorState.resetToZero()
                    self.webViewState = Atomic(value: .loadSuccess)
                    self.flushQueue()
                    completion?((.success(true), nil))
                }
            }
        }
    }

    /// Sends the track request to the webview.
    ///￼
    /// - Parameter track: `TealiumRequest` to be sent to the webview
    /// - Parameter completion: `ModuleCompletion?` block to be called when the request has been processed
    func dispatchTrack(_ request: TealiumRequest,
                       completion: ModuleCompletion?) {
        switch request {
        case let track as TealiumBatchTrackRequest:
            let allTrackData = track.trackRequests.map {
                $0.trackDictionary
            }
            #if TEST
            #else
            self.tagManagement?.trackMultiple(allTrackData) { success, _, error in
                TealiumQueues.backgroundConcurrentQueue.write {
                    guard error == nil else {
                        if let error = error {
                            completion?((.failure(error), nil))
                        }
                        return
                    }
                    completion?((.success(true), nil))
                }
            }
            #endif
        case let track as TealiumTrackRequest:
            #if TEST
            #else
            self.tagManagement?.track(track.trackDictionary) { success, _, error in
                TealiumQueues.backgroundConcurrentQueue.write {
                    guard error == nil else {
                        if let error = error {
                            completion?((.failure(error), nil))
                        }
                        return
                    }
                    completion?((.success(true), nil))
                }
            }
            #endif
        default:
            return
        }
    }

    /// Detects track type and dispatches appropriately.
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be a `TealiumTrackRequest`, `TealiumBatchTrackRequest` or a `TealiumRemoteCommandRequestResponse`
    /// - Parameter completion: `ModuleCompletion?` block to be called when the request has been processed
    public func dynamicTrack(_ track: TealiumRequest,
                             completion: ModuleCompletion?) {
        if self.errorState.value > 0 {
            self.tagManagement?.reload { success, _, _ in
                if success {
                    self.errorState.value = 0
                    self.dynamicTrack(track, completion: completion)
                } else {
                    _ = self.errorState.incrementAndGet()
                    self.enqueue(track, completion: completion)
                    completion?((.failure(TagManagementError.couldNotLoadURL), nil))
                }
            }
            return
        } else if self.webViewState == nil || self.tagManagement?.isWebViewReady == false {
            self.enqueue(track, completion: completion)
            return
        }

        flushQueue()

        switch track {
        case let track as TealiumTrackRequest:
            self.dispatchTrack(prepareForDispatch(track), completion: completion)
        case let track as TealiumBatchTrackRequest:
            let newRequest = TealiumBatchTrackRequest(trackRequests: track.trackRequests.map { prepareForDispatch($0) })
            self.dispatchTrack(newRequest, completion: completion)
        case let track as TealiumRemoteAPIRequest:
            self.dispatchTrack(prepareForDispatch(track.trackRequest), completion: completion)
            return
        case let command as TealiumRemoteCommandRequestResponse:
            if var jsCommand = command.data[TealiumKey.jsCommand] as? String {
                // Webview instance will ensure this is processed on the main thread
                jsCommand = jsCommand
                    .replacingOccurrences(of: "\\", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespaces)
                self.tagManagement?.evaluateJavascript(jsCommand, nil)
            }
            return
        default:
            return
        }
    }

    /// Enqueues a request for later dispatch if the webview isn't ready.
    ///
    /// - Parameter request: `TealiumRequest` to be enqueued
    /// - Parameter completion: `ModuleCompletion?` block to be called when the request has been processed
    func enqueue(_ request: TealiumRequest,
                 completion: ModuleCompletion?) {
        guard request is TealiumTrackRequest || request is TealiumBatchTrackRequest || request is TealiumRemoteAPIRequest else {
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
            self.pendingTrackRequests.append((TealiumBatchTrackRequest(trackRequests: requests), completion))
        case let request as TealiumTrackRequest:
            var track = request
            var trackData = track.trackDictionary
            trackData[TealiumKey.wasQueued] = true
            trackData[TealiumKey.queueReason] = "Tag Management Webview Not Ready"
            track.data = trackData.encodable
            self.pendingTrackRequests.append((track, completion))
        case let request as TealiumRemoteAPIRequest:
            self.pendingTrackRequests.append((request, completion))
        default:
            return
        }
    }

    /// Flushes any queued requests sent before the webview was ready
    func flushQueue() {
        let pending = self.pendingTrackRequests
        self.pendingTrackRequests = []
        pending.forEach {
            self.dynamicTrack($0.0, completion: $0.1)
        }
    }

    /// Adds dispatch service key to the dispatch.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        newTrack[TealiumKey.dispatchService] = TagManagementKey.moduleName
        return TealiumTrackRequest(data: newTrack)
    }

}
#endif
