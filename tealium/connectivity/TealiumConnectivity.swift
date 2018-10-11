//
//  TealiumConnectivity.swift
//  tealium-swift
//
//  Created by Jason Koo on 6/26/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation
import SystemConfiguration

public enum TealiumConnectivityConstants {
    public static let defaultInterval: Int = 60
}

public class TealiumConnectivity {

    static var connectionType: String?
    static var isConnected: Bool?
    // used to simulate connection status for unit tests
    static var forceConnectionOverride: Bool?
    var timer: DispatchSourceTimer?
    private var connectivityDelegates = TealiumMulticastDelegate<TealiumConnectivityDelegate>()
    var currentConnectivityType = ""
    static var currentConnectionStatus: Bool?

    public class func currentConnectionType() -> String {
        let isConnected = TealiumConnectivity.isConnectedToNetwork()
        if isConnected == true {
            return connectionType!
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
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags)
        #if os(OSX)
        connectionType = TealiumConnectivityKey.connectionTypeWifi
        #else
        if flags.contains(.isWWAN) == true {
            connectionType = TealiumConnectivityKey.connectionTypeCell
        } else if flags.contains(.connectionRequired) == false {
            connectionType = TealiumConnectivityKey.connectionTypeWifi
        }
        #endif

        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        isConnected = (isReachable && !needsConnection)
        if !isConnected! {
            connectionType = TealiumConnectivityKey.connectionTypeNone
        }

        return isConnected!
    }

}

public extension TealiumConnectivity {

    func addConnectivityDelegate(delegate: TealiumConnectivityDelegate) {
        connectivityDelegates.add(delegate)
    }

    func removeAllConnectivityDelegates() {
        connectivityDelegates.removeAll()
    }

    // MARK: Delegate Methods
    func connectionTypeChanged(_ connectionType: String) {
        connectivityDelegates.invoke {
            $0.connectionTypeChanged(connectionType)
        }
    }

    // MARK: Delegate Methods
    func connectionLost() {
        connectivityDelegates.invoke {
            $0.connectionLost()
        }
    }

    // MARK: Delegate Methods
    func connectionRestored() {
        connectivityDelegates.invoke {
            $0.connectionRestored()
        }
    }

    func refreshConnectivityStatus(_ interval: Int = TealiumConnectivityConstants.defaultInterval) {
        TealiumConnectivity.currentConnectionStatus = TealiumConnectivity.isConnectedToNetwork()
        let queue = DispatchQueue(label: "com.tealium.connectivity")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        // todo: make configurable
        timer?.schedule(deadline: .now(), repeating: .seconds(60), leeway: .seconds(interval))
        timer?.setEventHandler {
            let connected = TealiumConnectivity.isConnectedToNetwork()
            if let connectionType = TealiumConnectivity.connectionType {
                if connectionType != self.currentConnectivityType {
                    self.connectionTypeChanged(connectionType)
                }
                self.currentConnectivityType = connectionType
            }

            if connected != TealiumConnectivity.currentConnectionStatus {
                switch connected {
                case true:
                    self.connectionRestored()
                case false:
                    self.connectionLost()
                }
            }
            TealiumConnectivity.currentConnectionStatus = TealiumConnectivity.isConnectedToNetwork()
        }
        timer?.resume()
    }
}
