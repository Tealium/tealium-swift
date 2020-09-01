//
//  ConnectivityDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 16/5/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConnectivityDelegate: class {

    /// Called when network connectivity is lost.
    func connectionLost()

    /// Called when network connectivity is restored.
    func connectionRestored()
}
