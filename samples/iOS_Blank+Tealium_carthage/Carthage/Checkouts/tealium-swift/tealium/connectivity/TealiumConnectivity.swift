//
//  TealiumConnectivity.swift
//  SegueCatalog
//
//  Created by Jason Koo on 6/26/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration

enum TealiumConnectivityKey {
    static let moduleName = "connectivity"
    static let connectionType = "connection_type"
    static let wasQueued = "was_queued"
}

class TealiumConnectivityModule : TealiumModule {
    
    lazy var queue = [TealiumTrackRequest]()
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumConnectivityKey.moduleName,
                                   priority: 950,
                                   build: 1,
                                   enabled: true)
    }
    
    override func handle(_ request: TealiumRequest) {
        if let r = request as? TealiumEnableRequest {
            enable(r)
        }
        else if let r = request as? TealiumDisableRequest {
            disable(r)
        }
        else if let r = request as? TealiumTrackRequest {
            track(r)
        }
        else if let _ = request as? TealiumReleaseQueuesRequest {
            release(queue)
        }
        else {
            didFinishWithNoResponse(request)
        }
    }
    
    override func track(_ request: TealiumTrackRequest) {

        if isEnabled == false {
            didFinishWithNoResponse(request)
            return
        }
        
        if TealiumConnectivityModule.isConnectedToNetwork() == false {
            
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
            let report = TealiumReportRequest(message: "Connectivity: Internet connection available.")
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
        q.emptyFIFO { (track) in
            self.didFinish(track)
        }
    }

    
    // Nod to RAJAMOHAN-S
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        
        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)
        
        return ret
        
    }
    
    
}
