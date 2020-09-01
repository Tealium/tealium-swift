//
//  Dictionary+Tealium.swift
//  TealiumCore
//
//  Created by Jonathan Wong on 8/25/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Allows use of plus operator for array reduction calls.
func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}
