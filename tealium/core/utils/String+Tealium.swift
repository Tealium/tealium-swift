//
//  String+Tealium.swift
//  TealiumCore
//
//  Created by Jonathan Wong on 8/25/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Extend `boolValue` NSString function to Swift strings.
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}
