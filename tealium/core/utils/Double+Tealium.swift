//
//  Double+Tealium.swift
//  TealiumCore
//
//  Created by Jonathan Wong on 8/25/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Double {

    /// Converts seconds to milliseconds
    var milliseconds: Int64 {
        return Int64(self * 1000)
    }
}
