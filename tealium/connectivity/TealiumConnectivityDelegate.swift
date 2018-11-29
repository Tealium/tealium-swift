//
//  TealiumConnectivityDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 16/5/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumConnectivityDelegate: class {
    func connectionTypeChanged(_ connectionType: String)
    func connectionLost()
    func connectionRestored()
}
