//
//  TealiumConnectivityModule.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 tealium. All rights reserved.
//

import Foundation
#if os(watchOS)
#else
    import SystemConfiguration
#endif

enum TealiumConnectivityKey {
    static let moduleName = "connectivity"
    static let connectionType = "connection_type"
    static let wasQueued = "was_queued"
    static let connectionTypeWifi = "wifi"
    static let connectionTypeCell = "cellular"
    static let connectionTypeNone = "none"
}

class TealiumConnectivityModule: TealiumModule {

    lazy var queue = [TealiumTrackRequest]()
    static var connectionType: String?
    static var isConnected: Bool?
    // used to simulate connection status for unit tests
    static var forceConnectionOverride: Bool?

    @available(*, deprecated, message: "Internal only. Used only for unit tests. Using this method will disable connectivity checks.")
    public static func setConnectionOverride(shouldOverride override: Bool) {
        self.forceConnectionOverride = override
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
        } else if request as? TealiumReleaseQueuesRequest != nil {
            release(queue)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func track(_ request: TealiumTrackRequest) {
        if isEnabled == false {
            didFinishWithNoResponse(request)
            return
        }

        if TealiumConnectivity.isConnectedToNetwork() == false {

            // Save in cache
            queue(request)

            // Notify any logger
            let report = TealiumReportRequest(message: "Connectivity: Queued track. No internet connection.")
            delegate?.tealiumModuleRequests(module: self,
                                            process: report)

            // No did finish call. Halting further processing of track within
            //  module chain.
            return
        }

        if queue.isEmpty == false {
            let report = TealiumReportRequest(message: "Connectivity: Sending queued track. Internet connection available.")
            delegate?.tealiumModuleRequests(module: self,
                                            process: report)
            release(queue)
        }

        didFinishWithNoResponse(request)
    }

    func queue(_ track: TealiumTrackRequest) {
        var newData = track.data
        newData[TealiumConnectivityKey.wasQueued] = "true"
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: track.completion)
        queue.append(newTrack)
    }

    func release(_ queue: [TealiumTrackRequest]) {
        var q = queue
        q.emptyFIFO { track in
            self.didFinish(track)
        }
    }
}
