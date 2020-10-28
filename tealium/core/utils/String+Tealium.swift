//
//  String+Tealium.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Extend `boolValue` NSString function to Swift strings.
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}
