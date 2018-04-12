//
//  TealiumConnectivity.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/26/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration

public class TealiumConnectivity {

    static var connectionType: String?
    static var isConnected: Bool?
    // used to simulate connection status for unit tests
    static var forceConnectionOverride: Bool?

    public class func currentConnectionType() -> String {
        let isConnected = TealiumConnectivity.isConnectedToNetwork()
        if isConnected == true {
            return self.connectionType!
        }
        return TealiumConnectivityKey.connectionTypeNone
    }

    // Nod to RAJAMOHAN-S
    class func isConnectedToNetwork() -> Bool {
        // used only for unit testing
        if forceConnectionOverride == true {
            return true
        }

        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        #if os(OSX)
            self.connectionType = TealiumConnectivityKey.connectionTypeWifi
        #else
            if flags.contains(.isWWAN) == true {
                self.connectionType = TealiumConnectivityKey.connectionTypeCell
            } else if flags.contains(.connectionRequired) == false {
                self.connectionType = TealiumConnectivityKey.connectionTypeWifi
            }
        #endif

        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        self.isConnected = (isReachable && !needsConnection)
        if !self.isConnected! {
            self.connectionType = TealiumConnectivityKey.connectionTypeNone
        }

        return self.isConnected!
    }

}
