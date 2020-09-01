//
//  AutoTrackingExtensions.swift
//  TealiumAutotracking
//
//  Created by Craig Rouse on 01/07/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if autotracking
import TealiumCore
#endif

public extension Collectors {
    static let AutoTracking = AutotrackingModule.self
}
