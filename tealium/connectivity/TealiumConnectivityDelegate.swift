//
//  TealiumConnectivityDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 16/5/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumConnectivityDelegate: class {

    /// Called when network connection type has changed
    /// - Parameter connectionType: String containing the current connection type (wifi, cellular)
    func connectionTypeChanged(_ connectionType: String)

    /// Called when network connectivity is lost
    func connectionLost()

    /// Called when network connectivity is restored
    func connectionRestored()
}
