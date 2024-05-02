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
///
/// We assume all methods are called from the TealiumQueues.backgroundSerialQueue and all completion from the webview are reported into that same queue.
public class TagManagementModule: Dispatcher {

    public let id: String = ModuleNames.tagmanagement
    public var config: TealiumConfig
    var pendingTrackRequests = [(TealiumRequest, ModuleCompletion?)]()
    let tagManagement: TagManagementProtocol
    var webViewState: WebViewState?
    weak var delegate: ModuleDelegate?
    let disposeBag = TealiumDisposeBag()

    /// Provided for unit testing￼.
    ///
    /// - Parameter context: `TealiumContext` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter tagManagement: Class instance conforming to `TealiumTagManagementProtocol`
    init(context: TealiumContext,
         delegate: ModuleDelegate,
         tagManagement: TagManagementProtocol,
         completion: ModuleCompletion? = nil) {
        let config = context.config
        self.config = config
        self.delegate = delegate
        self.tagManagement = tagManagement
        TealiumQueues.backgroundSerialQueue.async { // This is required cause modules are not present yet
            TagManagementUrlBuilder(modules: context.modules, baseURL: config.webviewURL)
                .createUrl { [weak self] url in
                    self?.tagManagement.enable(webviewURL: url,
                                               delegates: config.webViewDelegates,
                                               view: config.rootView) { [weak self] _, error in
                        guard let self = self else { return }
                        if error != nil {
                            self.webViewState = .loadFailure
                            completion?((.failure(TagManagementError.webViewNotYetReady), nil))
                        } else {
                            self.webViewState = .loadSuccess
                            self.flushQueue()
                            completion?((.success(true), nil))
                        }
                    }
                }
            var currentSessionId: String? = context.dataLayer?.sessionId
            context.dataLayer?.onDataUpdated.subscribe { [weak self] updatedData in
                guard let self = self,
                      let newSessionId = updatedData[TealiumDataKey.sessionId] as? String,
                      currentSessionId != newSessionId else {
                    return
                }
                defer { currentSessionId = newSessionId }
                guard currentSessionId != nil else {
                    return
                }
                guard self.webViewState == .loadSuccess else {
                    return
                }
                self.webViewState = .loadFailure // Force reload on next track
            }.toDisposeBag(self.disposeBag)
        }
    }

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion?` block to be called when init is finished
    public required convenience init(context: TealiumContext,
                                     delegate: ModuleDelegate,
                                     completion: ModuleCompletion?) {
        self.init(context: context,
                  delegate: delegate,
                  tagManagement: TagManagementWKWebView(config: context.config, delegate: delegate),
                  completion: completion)
    }

    /// Sends the track request to the webview.
    /// ￼
    /// - Parameter track: `TealiumRequest` to be sent to the webview
    /// - Parameter completion: `ModuleCompletion?` block to be called when the request has been processed
    func dispatchTrack(_ request: TealiumRequest,
                       completion: ModuleCompletion?) {
        let block: TrackCompletion = { _, _, error in
            guard error == nil else {
                if let error = error {
                    completion?((.failure(error), nil))
                }
                return
            }
            completion?((.success(true), nil))
        }
        switch request {
        case let track as TealiumBatchTrackRequest:
            let allTrackData = track.trackRequests.map {
                $0.trackDictionary
            }
            #if TEST
            #else
            self.tagManagement.trackMultiple(allTrackData, completion: block)
            #endif
        case let track as TealiumTrackRequest:
            #if TEST
            #else
            self.tagManagement.track(track.trackDictionary, completion: block)
            #endif
        default:
            return
        }
    }

    func reload(completion: @escaping (Bool) -> Void) {
        self.tagManagement.reload { [weak self] success, _, _ in
            guard let self = self else { return }
            self.webViewState = success ? .loadSuccess : .loadFailure
            completion(success)
        }
    }

    /// Detects track type and dispatches appropriately.
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be a `TealiumTrackRequest`, `TealiumBatchTrackRequest` or a `TealiumRemoteCommandRequestResponse`
    /// - Parameter completion: `ModuleCompletion?` block to be called when the request has been processed
    public func dynamicTrack(_ track: TealiumRequest,
                             completion: ModuleCompletion?) {
        guard webViewState != nil else {
            self.enqueue(track, completion: completion)
            return
        }
        guard webViewState == .loadSuccess else {
            self.reload { success in
                if success {
                    self.dynamicTrack(track, completion: completion)
                } else {
                    self.enqueue(track, completion: completion)
                }
            }
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
            self.dispatchTrack(prepareForDispatch(track.trackRequest, overrideEventType: TealiumKey.remoteAPIEventType), completion: completion)
            return
        case let command as TealiumRemoteCommandRequestResponse:
            if var jsCommand = command.data[TealiumKey.jsCommand] as? String {
                // Webview instance will ensure this is processed on the main thread
                jsCommand = jsCommand
                    .replacingOccurrences(of: "\\", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .trimmingCharacters(in: .whitespaces)
                self.tagManagement.evaluateJavascript(jsCommand, nil)
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
                trackData[TealiumDataKey.wasQueued] = true
                trackData[TealiumDataKey.queueReason] = "Tag Management Webview Not Ready"
                track.data = trackData.encodable
                return track
            }
            self.pendingTrackRequests.append((TealiumBatchTrackRequest(trackRequests: requests), completion))
        case let request as TealiumTrackRequest:
            var track = request
            var trackData = track.trackDictionary
            trackData[TealiumDataKey.wasQueued] = true
            trackData[TealiumDataKey.queueReason] = "Tag Management Webview Not Ready"
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
    func prepareForDispatch(_ request: TealiumTrackRequest, overrideEventType: String? = nil) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        newTrack[TealiumDataKey.dispatchService] = TagManagementKey.moduleName
        if let newEventType = overrideEventType {
            newTrack[TealiumDataKey.eventType] = newEventType
        }
        return TealiumTrackRequest(data: newTrack)
    }

}
#endif
