//
//  TealiumCollectModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

/// Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
class TealiumCollectModule: TealiumModule {

    var collect: TealiumCollectProtocol?
    var config: TealiumConfig?
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1050,
                                   build: 4,
                                   enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumTrackRequest:
            dynamicTrack(request)
        case let request as TealiumBatchTrackRequest:
            dynamicTrack(request)
        default:
            didFinish(request)
        }
    }

    /// Enables the module and loads sets up a dispatcher￼.
    ///
    /// - Parameter request: `TealiumEnableRequest` - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        config = request.config
        if self.collect == nil {
            // Collect dispatch service
            let urlString = config?.optionalData[TealiumCollectKey.overrideCollectUrl] as? String ?? TealiumCollectPostDispatcher.defaultDispatchBaseURL
            self.collect = TealiumCollectPostDispatcher(dispatchURL: urlString) { _, _ in
                self.didFinish(request)
                return
            }
        }
        didFinishWithNoResponse(request)
    }

    /// Detects track type and dispatches appropriately, adding mandatory data (account and profile) to the track if missing.￼
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    func dynamicTrack(_ track: TealiumRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(track)
            return
        }

        guard collect != nil else {
            didFailToFinish(track,
                            error: TealiumCollectError.collectNotInitialized)
            return
        }

        switch track {
        case let track as TealiumTrackRequest:
            guard track.trackDictionary[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName else {
                didFinishWithNoResponse(track)
                return
            }
            self.track(prepareForDispatch(track))
        case let track as TealiumBatchTrackRequest:
            var requests = track.trackRequests
            requests = requests.filter {
                $0.trackDictionary[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName
            }.map {
                prepareForDispatch($0)
            }
            var newRequest = TealiumBatchTrackRequest(trackRequests: requests, completion: track.completion)
            newRequest.moduleResponses = track.moduleResponses
            self.batchTrack(newRequest)
        default:
            self.didFinishWithNoResponse(track)
            return
        }
    }

    /// Adds required account information to the dispatch if missing￼.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        if newTrack[TealiumKey.account] == nil,
            newTrack[TealiumKey.profile] == nil {
            newTrack[TealiumKey.account] = config?.account
            newTrack[TealiumKey.profile] = config?.profile
        }

        if let profileOverride = config?.optionalData[TealiumCollectKey.overrideCollectProfile] as? String {
            newTrack[TealiumKey.profile] = profileOverride
        }

        newTrack[TealiumKey.dispatchService] = TealiumCollectKey.moduleName
        return TealiumTrackRequest(data: newTrack, completion: request.completion)
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be dispatched
    override func track(_ track: TealiumTrackRequest) {
        guard let collect = collect else {
            didFinishWithNoResponse(track)
            return
        }

        // Send the current track call
        let data = track.trackDictionary

        collect.dispatch(data: data, completion: { success, info, error in

            track.completion?(success, info, error)

            // Let the modules manager know we had a failure.
            guard success else {
                let localError = error ?? TealiumCollectError.unknownIssueWithSend
                self.didFailToFinish(track,
                                     info: info,
                                     error: localError)
                return
            }

            var trackInfo = info ?? [String: Any]()
            trackInfo += [TealiumCollectKey.payload: track.trackDictionary]

            // Another message to moduleManager of completed track, this time of
            //  modified track data.
            self.didFinish(track,
                           info: trackInfo)
        })
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumBatchTrackRequest` to be dispatched
    func batchTrack(_ request: TealiumBatchTrackRequest) {
        guard let collect = collect else {
            didFinishWithNoResponse(request)
            return
        }

        guard let compressed = request.compressed() else {
            let logRequest = TealiumReportRequest(message: "Batch track request failed. Will not be sent.")
            delegate?.tealiumModuleRequests(module: self, process: logRequest)
            return
        }

        collect.dispatchBulk(data: compressed) { success, info, error in

            guard success else {
                let localError = error ?? TealiumCollectError.unknownIssueWithSend
                self.didFailToFinish(request,
                                     info: info,
                                     error: localError)
                let logRequest = TealiumReportRequest(message: "Batch track request failed. Error: \(error?.localizedDescription ?? "unknown")")
                self.delegate?.tealiumModuleRequests(module: self, process: logRequest)
                return
            }

            self.didFinish(request, info: info)
        }
    }

    /// Called when the module successfully finished processing a request￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumRequest` that was processed￼
    ///     - info: `[String: Any]?` containing additional information about the request processing
    func didFinish(_ request: TealiumRequest,
                   info: [String: Any]?) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        response.info = info
        newRequest.moduleResponses.append(response)

        delegate?.tealiumModuleFinished(module: self,
                                        process: newRequest)
    }

    /// Called when the module failed for to complete a request￼.
    ///
    /// - Parameters:
    ///     - request: `TealiumRequest` that failed￼
    ///     - info: `[String: Any]? `containing information about the failure￼
    ///     - error: `Error` with precise information about the failure
    func didFailToFinish(_ request: TealiumRequest,
                         info: [String: Any]?,
                         error: Error) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: false,
                                             error: error)
        if let error = error as? URLError,
        error.code == URLError.notConnectedToInternet || error.code == URLError.networkConnectionLost || error.code == URLError.timedOut {

            switch request {
            case let request as TealiumTrackRequest:
                let enqueueRequest = TealiumEnqueueRequest(data: request, queueReason: "connectivity", completion: nil)
                delegate?.tealiumModuleRequests(module: self, process: enqueueRequest)
            case let request as TealiumBatchTrackRequest:
                let enqueueRequest = TealiumEnqueueRequest(data: request, queueReason: "connectivity", completion: nil)
                delegate?.tealiumModuleRequests(module: self, process: enqueueRequest)
            default:
                return
            }

            let connectivityRequest = TealiumConnectivityRequest(status: .notReachable)
            delegate?.tealiumModuleRequests(module: self, process: connectivityRequest)
        } else {
            response.info = info
            newRequest.moduleResponses.append(response)
            delegate?.tealiumModuleFinished(module: self,
                                            process: newRequest)
        }
    }

    /// Disables the module￼.
    ///
    /// - Parameter request: `TealiumDisableRequest`
    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        self.collect = nil
        didFinish(request)
    }

    deinit {
        self.config = nil
        self.collect = nil
    }

}
