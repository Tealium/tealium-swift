//
//  TealiumConnectivityModule.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

#if connectivity
import TealiumCore
#endif

class TealiumConnectivityModule: TealiumModule {

    static var connectionType: String?
    static var isConnected: Bool?
    // used to simulate connection status for unit tests
    lazy var connectivity = TealiumConnectivity()

    @available(*, deprecated, message: "Internal only. Used only for unit tests. Using this method will disable connectivity checks.")
    public static func setConnectionOverride(shouldOverride override: Bool) {
        TealiumConnectivity.forceConnectionOverride = override
    }

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumConnectivityKey.moduleName,
                                   priority: 950,
                                   build: 1,
                                   enabled: true)
    }

    /// Custom handler for incoming module requests.
    ///
    /// - Parameter request: TealiumRequest to be handled by the module
    override func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            dynamicDispatch(request)
        case let request as TealiumBatchTrackRequest:
            dynamicDispatch(request)
        case let request as TealiumConnectivityRequest:
            handleConnectivityReport(request: request)
        case let request as TealiumUpdateConfigRequest:
            updateConfig(request)
        default:
            didFinishWithNoResponse(request)
        }
    }

    /// Detects track type and dispatches appropriately, adding mandatory data (account and profile) to the track if missing.
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    func dynamicDispatch(_ track: TealiumRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(track)
            return
        }

        switch track {
        case let track as TealiumTrackRequest:
            self.trackWithConnectivityCheck(prepareForDispatch(track))
        case let track as TealiumBatchTrackRequest:
            var requests = track.trackRequests
            requests = requests.map {
                prepareForDispatch($0)
            }
            var newRequest = TealiumBatchTrackRequest(trackRequests: requests, completion: track.completion)
            newRequest.moduleResponses = track.moduleResponses
            self.trackWithConnectivityCheck(newRequest)
        default:
            self.didFinishWithNoResponse(track)
            return
        }
    }

    /// Adds connectivity information to the dispatch.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        let request = addModuleName(to: request)
        var newData = request.trackDictionary
        // do not add data to queued hits
        if newData[TealiumKey.wasQueued] as? String == nil {
            if let connectionType = TealiumConnectivity.connectionType {
                newData += [TealiumConnectivityKey.connectionType: connectionType,
                            TealiumConnectivityKey.connectionTypeLegacy: connectionType,
                ]
            }
        }
        var newRequest = TealiumTrackRequest(data: newData, completion: request.completion)
        newRequest.moduleResponses = request.moduleResponses
        return newRequest
    }

    /// Enables the module and starts connectivity monitoring.
    ///
    /// - Parameter request: `TealiumEnableRequest` - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        connectivity.addConnectivityDelegate(delegate: self)
        self.config = request.config
        self.refreshConnectivityStatus()
        if !request.bypassDidFinish {
            didFinishWithNoResponse(request)
        }
    }

    /// Handles the track request and queues if no connection available (requires DispatchQueue module).
    ///
    /// - Parameter track: `TealiumTrackRequest` to be processed
    func trackWithConnectivityCheck(_ request: TealiumRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(request)
            return
        }

        if TealiumConnectivity.isConnectedToNetwork() == false || (config?.wifiOnlySending == true &&
        TealiumConnectivity.currentConnectionType() != TealiumConnectivityKey.connectionTypeWifi) {
            self.refreshConnectivityStatus()
            // Save in cache
            enqueue(request)

            // Notify any logger
            let report = TealiumReportRequest(message: "Connectivity: Queued track. No internet connection.")
            delegate?.tealiumModuleRequests(module: self,
                                            process: report)

            // No did finish call. Halting further processing of track within module chain.
            return
        }

        cancelConnectivityRefresh()

        let report = TealiumReportRequest(message: "Connectivity: Sending queued track. Internet connection available.")
        delegate?.tealiumModuleRequests(module: self, process: report)

        didFinishWithNoResponse(request)
    }

    /// Enqueues the track request for later transmission.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be queued
    func enqueue(_ track: TealiumRequest) {
        var enqueueRequest: TealiumEnqueueRequest
        switch track {
        case let track as TealiumTrackRequest:
            var newTrack = addQueueData(track)
            newTrack.moduleResponses = track.moduleResponses
            enqueueRequest = TealiumEnqueueRequest(data: newTrack, completion: nil)
        case let track as TealiumBatchTrackRequest:
            var requests = track.trackRequests
            requests = requests.map {
                addQueueData($0)
            }
            var newRequest = TealiumBatchTrackRequest(trackRequests: requests, completion: track.completion)
            newRequest.moduleResponses = track.moduleResponses
            enqueueRequest = TealiumEnqueueRequest(data: newRequest, completion: nil)
        default:
            self.didFinishWithNoResponse(track)
            return
        }

        delegate?.tealiumModuleRequests(module: self, process: enqueueRequest)
    }

    func handleConnectivityReport(request: TealiumConnectivityRequest) {
        if request.connectivityStatus == .notReachable {
            TealiumConnectivity.isConnected = Atomic(value: false)
            TealiumConnectivity.currentConnectionStatus = false
            connectivity.connectionLost()
        }
    }

    /// Adds queue reason to track request.
    ///
    /// - Parameter track: `TealiumTrackRequest`
    /// - Returns: `TealiumTrackRequest`
    func addQueueData(_ track: TealiumTrackRequest) -> TealiumTrackRequest {
        var newData = track.trackDictionary
        newData[TealiumKey.queueReason] = TealiumConnectivityKey.moduleName
        newData[TealiumKey.wasQueued] = "true"
        return TealiumTrackRequest(data: newData,
                                   completion: track.completion)
    }

    /// Releases all queued track calls for dispatch.
    func release() {
        // queue will be released, but will only be allowed to continue if tracking is allowed when track call is resubmitted
        let req = TealiumReleaseQueuesRequest(typeId: "connectivity", moduleResponses: [TealiumModuleResponse]()) { _, _, _ in
            let report = TealiumReportRequest(message: "Connectivity: Attempting to send queued track call.")
            self.delegate?.tealiumModuleRequests(module: self,
                                                 process: report)
        }
        delegate?.tealiumModuleRequests(module: self, process: req)
    }

    /// Starts monitoring for connectivity changes.
    func refreshConnectivityStatus() {
        if let interval = config?.connectivityRefreshInterval {
            connectivity.refreshConnectivityStatus(interval)
        } else {
            if config?.connectivityRefreshEnabled == false {
                return
            }
            connectivity.refreshConnectivityStatus()
        }
    }

    /// Cancels automatic connectivity checks.
    func cancelConnectivityRefresh() {
        connectivity.cancelAutoStatusRefresh()
    }
}
