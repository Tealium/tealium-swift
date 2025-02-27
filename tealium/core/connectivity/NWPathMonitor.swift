//
//  NWPathMonitor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if canImport(Network)
import Network
#endif

#if !os(watchOS)
class TealiumNWPathMonitor: ConnectivityMonitorProtocol {

    var currentConnectionType: String? {
        guard isConnected == true else {
            return ConnectivityKey.connectionTypeNone
        }
        if isCellular == true {
            return ConnectivityKey.connectionTypeCell
        }
        if isWifi == true {
            return ConnectivityKey.connectionTypeWifi
        }

        if isWired == true {
            return ConnectivityKey.connectionTypeWired
        }
        return TealiumValue.unknown
    }

    var monitor = NWPathMonitor()
    let queue = TealiumQueues.backgroundSerialQueue

    var isConnected: Bool? {
        let connected = (monitor.currentPath.status == .satisfied)
        if config.wifiOnlySending == true, isExpensive == true {
            return false
        } else {
            return connected
        }
    }

    var isExpensive: Bool? {
        monitor.currentPath.isExpensive
    }

    var isCellular: Bool? {
        monitor.currentPath.usesInterfaceType(.cellular)
    }

    var isWifi: Bool? {
        monitor.currentPath.usesInterfaceType(.wifi)
    }

    var isWired: Bool? {
        monitor.currentPath.usesInterfaceType(.wiredEthernet)
    }

    var completion: ((Result<Bool, Error>) -> Void)

    var config: TealiumConfig

    required init(config: TealiumConfig,
                  completion: @escaping ((Result<Bool, Error>) -> Void)) {
        self.config = config
        self.completion = completion

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else {
                return
            }
            switch path.status {
            case .satisfied:
                if self.config.wifiOnlySending == true, path.isExpensive {
                    self.completion(.failure(TealiumConnectivityError.noConnection))
                } else {
                    self.completion(.success(true))
                }
            default:
                self.completion(.failure(TealiumConnectivityError.noConnection))
            }
        }
        monitor.start(queue: queue)
    }

    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        switch isConnected {
        case true:
            completion(.success(true))
        default:
            completion(.failure(TealiumConnectivityError.noConnection))
        }
    }

    deinit {
        monitor.cancel()
    }

}

#endif

enum TealiumConnectivityError: TealiumErrorEnum {
    case noConnection
}
