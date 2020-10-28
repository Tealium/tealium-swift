//
//  LegacyConnectivityMonitor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

#if canImport(SystemConfiguration)
import SystemConfiguration
#endif

class LegacyConnectivityMonitor: ConnectivityMonitorProtocol {
    var currentConnnectionType: String? {
        #if os(watchOS)
        return TealiumValue.unknown
        #else
        if isConnected == true {
            return connectionType
        } else {
            return ConnectivityKey.connectionTypeNone
        }
        #endif
    }
    var connectionType: String?

    var isConnected: Bool? {
        #if os(watchOS)
        return false
        #else
        let connected = isConnectedToNetwork()
        if config.wifiOnlySending == true, currentConnnectionType != ConnectivityKey.connectionTypeWifi {
            return false
        } else {
            return connected
        }
        #endif
    }

    var isExpensive: Bool? {
        isCellular
    }

    var isCellular: Bool? {
        currentConnnectionType == ConnectivityKey.connectionTypeCell
    }

    var isWired: Bool? {
        false
    }

    var timer: TealiumRepeatingTimer?
    var currentConnectionStatus: Bool?

    var completion: ((Result<Bool, Error>) -> Void)
    var config: TealiumConfig
    var urlSession: URLSessionProtocol?

    convenience init (config: TealiumConfig,
                      completion: @escaping ((Result<Bool, Error>) -> Void),
                      urlSession: URLSessionProtocol) {
        self.init(config: config, completion: completion)
        self.urlSession = urlSession
    }

    required init(config: TealiumConfig,
                  completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
        self.urlSession = URLSession(configuration: .ephemeral)
        self.completion = completion
        if let interval = config.connectivityRefreshInterval {
            self.refreshConnectivityStatus(interval)
        } else {
            if config.connectivityRefreshEnabled == true {
                self.refreshConnectivityStatus()
            }
        }
        self.checkIsConnected(completion: completion)
    }

    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        #if os(watchOS)
        checkConnectionFromURLSessionTask(completion: completion)
        #else
        switch self.isConnectedToNetwork() {
        case true:
            self.connectionRestored()
            completion(.success(true))
        case false:
            completion(.failure(TealiumConnectivityError.noConnection))
            self.connectionLost()
        }
        #endif
    }

    func checkConnectionFromURLSessionTask(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        let session = self.urlSession ?? URLSession(configuration: .ephemeral)
        guard let testURL = URL(string: ConnectivityConstants.connectivityTestURL) else {
            return
        }
        var request = URLRequest(url: testURL)
        request.httpMethod = "HEAD"
        let task = session.tealiumDataTask(with: request) { _, _, error in
            if let _ = error as? URLError {
                self.connectionLost()
                completion(.failure(TealiumConnectivityError.noConnection))
            } else {
                self.connectionRestored()
                completion(.success(true))
            }
        }
        task.resume()
    }

    #if os(watchOS)
    #else
    // Credit: RAJAMOHAN-S: https://stackoverflow.com/questions/30743408/check-for-internet-connection-with-swift/39782859#39782859
    /// Determines if the device has network connectivity.
    ///
    /// - Returns: `Bool` (true if device has connectivity)
    func isConnectedToNetwork() -> Bool {
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
        connectionType = ConnectivityKey.connectionTypeWifi
        #else
        if flags.contains(.isWWAN) == true {
            connectionType = ConnectivityKey.connectionTypeCell
        } else if flags.contains(.connectionRequired) == false {
            connectionType = ConnectivityKey.connectionTypeWifi
        }
        #endif

        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }

        // Working for Cellular and WIFI
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let isConnected = (isReachable && !needsConnection)
        if !isConnected {
            connectionType = ConnectivityKey.connectionTypeNone
        }

        return isConnected
    }
    #endif

    /// Sets a timer to check for connectivity status updates￼.
    ///
    /// - Parameter interval: `Int` representing the time interval in seconds for new connectivity checks
    func refreshConnectivityStatus(_ interval: Int = ConnectivityConstants.defaultInterval) {
        // already an active timer, so don't start a new one
        if timer != nil {
            return
        }
        #if os(watchOS)
        self.currentConnectionStatus = false
        #else
        self.currentConnectionStatus = isConnectedToNetwork()
        #endif

        let queue = DispatchQueue(label: "com.tealium.connectivity")
        guard let timeInterval = TimeInterval(exactly: interval) else {
            return
        }
        timer = TealiumRepeatingTimer(timeInterval: timeInterval, dispatchQueue: queue)
        timer?.eventHandler = { [weak self] in
            guard let self = self else {
                return
            }
            #if os(watchOS)
            self.checkConnectionFromURLSessionTask { result in
                switch result {
                case .success:
                    self.connectionRestored()
                case .failure:
                    self.connectionLost()
                }
            }
            #else
            let connected = self.isConnectedToNetwork()
            if connected != self.currentConnectionStatus {
                switch connected {
                case true:
                    self.connectionRestored()
                case false:
                    self.connectionLost()
                }
            }
            #endif
        }
        timer?.resume()
    }

    func connectionRestored() {
        self.cancelAutoStatusRefresh()
        if self.currentConnectionStatus == false {
            self.currentConnectionStatus = true
            self.completion(.success(true))
        }
    }

    func connectionLost() {
        self.refreshConnectivityStatus()
        if self.currentConnectionStatus == true {
            self.currentConnectionStatus = false
            self.completion(.failure(TealiumConnectivityError.noConnection))
        }
    }

    /// Stops scheduled checks for connectivity.
    func cancelAutoStatusRefresh() {
        timer?.suspend()
    }

    deinit {
        timer = nil
    }
}
