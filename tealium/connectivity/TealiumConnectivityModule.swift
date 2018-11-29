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

enum TealiumConnectivityKey {
    static let moduleName = "connectivity"
    static let connectionType = "network_connection_type"
    static let connectionTypeWifi = "wifi"
    static let connectionTypeCell = "cellular"
    static let connectionTypeNone = "none"
    static let refreshIntervalKey = "refresh_interval"
    static let refreshEnabledKey = "refresh_enabled"
}

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

    override func enable(_ request: TealiumEnableRequest) {
        super.enable(request)
        connectivity.addConnectivityDelegate(delegate: self)
        self.config = request.config
        self.refreshConnectivityStatus()
    }

    override func track(_ request: TealiumTrackRequest) {
        if isEnabled == false {
            didFinishWithNoResponse(request)
            return
        }

        var newData = request.data
        newData += [TealiumConnectivityKey.connectionType: TealiumConnectivity.currentConnectionType()]
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

            // No did finish call. Halting further processing of track within
            //  module chain.
            return
        }

        cancelConnectivityRefresh()

        let report = TealiumReportRequest(message: "Connectivity: Sending queued track. Internet connection available.")
        delegate?.tealiumModuleRequests(module: self, process: report)

        release()

        didFinishWithNoResponse(newTrack)
    }

    func queue(_ track: TealiumTrackRequest) {
        var newData = track.data
        newData[TealiumKey.queueReason] = TealiumConnectivityKey.moduleName
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        let req = TealiumEnqueueRequest(data: newTrack, completion: nil)
        delegate?.tealiumModuleRequests(module: self, process: req)
    }

    func release() {
        // queue will be released, but will only be allowed to continue if tracking is allowed when track call is resubmitted
        let req = TealiumReleaseQueuesRequest(typeId: "connectivity", moduleResponses: [TealiumModuleResponse]()) { _, _, _ in
            let report = TealiumReportRequest(message: "Connectivity: Attempting to send queued track call.")
            self.delegate?.tealiumModuleRequests(module: self,
                                                 process: report)
        }
        delegate?.tealiumModuleRequests(module: self, process: req)
    }

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

    func cancelConnectivityRefresh() {
        connectivity.cancelAutoStatusRefresh()
    }

}

extension TealiumConnectivityModule: TealiumConnectivityDelegate {
    func connectionTypeChanged(_ connectionType: String) {
        let report = TealiumReportRequest(message: "Connectivity: Connection type changed to \(connectionType)")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
    }

    func connectionLost() {
        let report = TealiumReportRequest(message: "Connectivity: Connection lost; queueing dispatches")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
    }

    func connectionRestored() {
        let report = TealiumReportRequest(message: "Connectivity: Connection restored; releasing queue")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
        release()
    }
}

public extension TealiumConfig {
    func setConnectivityRefreshInterval(interval: Int) {
        optionalData[TealiumConnectivityKey.refreshIntervalKey] = interval
    }

    func setConnectivityRefreshEnabled(enabled: Bool) {
        optionalData[TealiumConnectivityKey.refreshEnabledKey] = enabled
    }
}
