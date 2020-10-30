//
//  ConnectivityDelegate.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConnectivityDelegate: class {

    /// Called when network connectivity is lost.
    func connectionLost()

    /// Called when network connectivity is restored.
    func connectionRestored()
}
