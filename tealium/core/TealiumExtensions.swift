//
//  TealiumExtensions.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

/**
     General Extensions that may be used by multiple objects.
*/
import Foundation

/**
 Extend boolvalue NSString function to Swift strings.
 */
extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}

/**
 Allows use of plus operator for array reduction calls.
 */
fileprivate func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach{ result[$0] = $1 }
    return result
}
