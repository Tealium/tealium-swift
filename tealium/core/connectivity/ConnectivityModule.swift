//
//  ConnectivityModule.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

protocol ConnectivityMonitorProtocol {
    init(config: TealiumConfig,
         completion: @escaping ((Result<Bool, Error>) -> Void))
    var config: TealiumConfig { get set }
    var currentConnnectionType: String? { get }
    var isConnected: Bool? { get }
    var isExpensive: Bool? { get }
    var isCellular: Bool? { get }
    var isWired: Bool? { get }
    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void))
}

public class ConnectivityModule: Collector, ConnectivityDelegate {

    public var id: String = ModuleNames.connectivity

    public var data: [String: Any]? {
        if let connectionType = self.connectivityMonitor?.currentConnnectionType {
            return [ConnectivityKey.connectionType: connectionType,
            ]
        } else {
            return [ConnectivityKey.connectionType: TealiumValue.unknown,
            ]
        }
    }

    public var config: TealiumConfig {
        willSet {
            connectivityMonitor?.config = newValue
        }
    }

    // used to simulate connection status for unit tests
    var forceConnectionOverride: Bool?

    var connectivityMonitor: ConnectivityMonitorProtocol?
    var connectivityDelegates = TealiumMulticastDelegate<ConnectivityDelegate>()

    required public init(context: TealiumContext,
                         delegate: ModuleDelegate?,
                         diskStorage: TealiumDiskStorageProtocol?,
                         completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.config = context.config

        if #available(iOS 12.0, tvOS 12.0, watchOS 5.0, OSX 10.14, *) {
            self.connectivityMonitor = TealiumNWPathMonitor(config: self.config) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success:
                    self.connectionRestored()
                case .failure:
                    self.connectionLost()
                }
            }
        } else {
            self.connectivityMonitor = LegacyConnectivityMonitor(config: self.config) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success:
                    self.connectionRestored()
                case .failure:
                    self.connectionLost()
                }
            }
        }
    }

    func checkIsConnected(completion: @escaping ((Result<Bool, Error>) -> Void)) {
        guard forceConnectionOverride == nil || forceConnectionOverride == false else {
            completion(.success(true))
            return
        }
        self.connectivityMonitor?.checkIsConnected(completion: completion)
    }

    /// Method to add new classes implementing the ConnectivityDelegate to subscribe to connectivity updates￼.
    ///
    /// - Parameter delegate: `ConnectivityDelegate`
    func addConnectivityDelegate(delegate: ConnectivityDelegate) {
        connectivityDelegates.add(delegate)
    }

    /// Removes all connectivity delegates.
    func removeAllConnectivityDelegates() {
        connectivityDelegates.removeAll()
    }

    // MARK: Delegate Methods

    /// Called when network connectivity is lost.
    public func connectionLost() {
        connectivityDelegates.invoke {
            $0.connectionLost()
        }
    }

    /// Called when network connectivity is restored.
    public func connectionRestored() {
        connectivityDelegates.invoke {
            $0.connectionRestored()
        }
    }
}
