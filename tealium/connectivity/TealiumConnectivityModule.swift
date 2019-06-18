//
//  TealiumConnectivityModule.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

#if os(watchOS)
#else
import SystemConfiguration
#endif
#if connectivity
import TealiumCore
#endif

class TealiumConnectivityModule: TealiumModule {

    static var connectionType: String?
    static var isConnected: Bool?
    // used to simulate connection status for unit tests
    lazy var connectivity = TealiumConnectivity()
    var config: TealiumConfig?

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

    /// Custom handler for incoming module requests
    ///
    /// - Parameter request: TealiumRequest to be handled by the module
    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumTrackRequest {
            track(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    /// Enables the module and starts connectivity monitoring
    ///
    /// - Parameter request: TealiumEnableRequest - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        super.enable(request)
        connectivity.addConnectivityDelegate(delegate: self)
        self.config = request.config
        self.refreshConnectivityStatus()
    }

    /// Handles the track request and queues if no connection available (requires DispatchQueue module)
    ///
    /// - Parameter track: TealiumTrackRequest to be processed
    override func track(_ request: TealiumTrackRequest) {
        if isEnabled == false {
            didFinishWithNoResponse(request)
            return
        }

        var newData = request.data
        newData += [TealiumConnectivityKey.connectionType: TealiumConnectivity.currentConnectionType(),
                    TealiumConnectivityKey.connectionTypeLegacy: TealiumConnectivity.currentConnectionType(),
        ]
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: request.completion)

        if TealiumConnectivity.isConnectedToNetwork() == false {
            self.refreshConnectivityStatus()
            // Save in cache
            queue(newTrack)

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

        release()

        didFinishWithNoResponse(newTrack)
    }

    /// Enqueues the track request for later transmission
    ///
    /// - Parameter track: TealiumTrackRequest to be queued
    func queue(_ track: TealiumTrackRequest) {
        var newData = track.data
        newData[TealiumKey.queueReason] = TealiumConnectivityKey.moduleName
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        let req = TealiumEnqueueRequest(data: newTrack, completion: nil)
        delegate?.tealiumModuleRequests(module: self, process: req)
    }

    /// Releases all queued track calls for dispatch
    func release() {
        // queue will be released, but will only be allowed to continue if tracking is allowed when track call is resubmitted
        let req = TealiumReleaseQueuesRequest(typeId: "connectivity", moduleResponses: [TealiumModuleResponse]()) { _, _, _ in
            let report = TealiumReportRequest(message: "Connectivity: Attempting to send queued track call.")
            self.delegate?.tealiumModuleRequests(module: self,
                                                 process: report)
        }
        delegate?.tealiumModuleRequests(module: self, process: req)
    }

    /// Starts monitoring for connectivity changes
    func refreshConnectivityStatus() {
        if let interval = config?.optionalData[TealiumConnectivityKey.refreshIntervalKey] as? Int {
            connectivity.refreshConnectivityStatus(interval)
        } else {
            if config?.optionalData[TealiumConnectivityKey.refreshEnabledKey] as? Bool == false {
                return
            }
            connectivity.refreshConnectivityStatus()
        }
    }

    /// Cancels automatic connectivity checks
    func cancelConnectivityRefresh() {
        connectivity.cancelAutoStatusRefresh()
    }
}
