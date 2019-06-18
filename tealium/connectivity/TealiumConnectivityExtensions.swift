//
//  TealiumConnectivityExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConnectivity {

    /// Method to add new classes implementing the TealiumConnectivityDelegate to subscribe to connectivity updates
    ///
    /// - Parameter delegate: TealiumConnectivityDelegate
    func addConnectivityDelegate(delegate: TealiumConnectivityDelegate) {
        connectivityDelegates.add(delegate)
    }

    /// Removes all connectivity delegates
    func removeAllConnectivityDelegates() {
        connectivityDelegates.removeAll()
    }

    // MARK: Delegate Methods
    /// Called when network connection type has changed
    /// - Parameter connectionType: String containing the current connection type (wifi, cellular)
    func connectionTypeChanged(_ connectionType: String) {
        connectivityDelegates.invoke {
            $0.connectionTypeChanged(connectionType)
        }
    }

    /// Called when network connectivity is lost
    func connectionLost() {
        connectivityDelegates.invoke {
            $0.connectionLost()
        }
    }

    /// Called when network connectivity is restored
    func connectionRestored() {
        connectivityDelegates.invoke {
            $0.connectionRestored()
        }
    }

    /// Sets a timer to check for connectivity status updates
    ///
    /// - Parameter interval: Int representing the time interval in seconds for new connectivity checks
    func refreshConnectivityStatus(_ interval: Int = TealiumConnectivityConstants.defaultInterval) {
        // already an active timer, so don't start a new one
        if timer != nil {
            return
        }
        TealiumConnectivity.currentConnectionStatus = TealiumConnectivity.isConnectedToNetwork()
        let queue = DispatchQueue(label: "com.tealium.connectivity")
        guard let timeInterval = TimeInterval(exactly: interval) else {
            return
        }
        timer = TealiumRepeatingTimer(timeInterval: timeInterval, dispatchQueue: queue)
        timer?.eventHandler = {
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

    /// Stops scheduled checks for connectivity
    func cancelAutoStatusRefresh() {
        timer?.suspend()
        timer = nil
    }
}
