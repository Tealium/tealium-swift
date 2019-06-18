//
//  TealiumConnectivityModuleExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if connectivity
import TealiumCore
#endif

extension TealiumConnectivityModule: TealiumConnectivityDelegate {

    /// Called when network connection type has changed
    /// - Parameter connectionType: String containing the current connection type (wifi, cellular)
    func connectionTypeChanged(_ connectionType: String) {
        let report = TealiumReportRequest(message: "Connectivity: Connection type changed to \(connectionType)")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
    }

    /// Called when network connectivity is lost
    func connectionLost() {
        let report = TealiumReportRequest(message: "Connectivity: Connection lost; queueing dispatches")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
    }

    /// Called when network connectivity is restored
    func connectionRestored() {
        let report = TealiumReportRequest(message: "Connectivity: Connection restored; releasing queue")
        self.delegate?.tealiumModuleRequests(module: self,
                                             process: report)
        release()
    }
}
