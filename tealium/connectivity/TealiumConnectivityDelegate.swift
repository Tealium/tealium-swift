//
// Created by Craig Rouse on 16/05/2018.
// Copyright (c) 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumConnectivityDelegate: class {
    func connectionTypeChanged(_ connectionType: String)
    func connectionLost()
    func connectionRestored()
}
