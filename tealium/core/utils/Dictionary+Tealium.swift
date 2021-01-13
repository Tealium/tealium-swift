//
//  Dictionary+Tealium.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

/// Allows use of plus operator for array reduction calls.
func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
    var result = lhs
    rhs.forEach { result[$0] = $1 }
    return result
}

/// Extend the use of += operators to dictionaries.
public func +=<K, V>(left: inout [K: V], right: [K: V]) {
    for (key, value) in right {
        left.updateValue(value, forKey: key)
    }
}

/// Extend use of == to dictionaries.
public func ==(lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public extension Dictionary where Key == String, Value == Any {

    var codable: AnyCodable {
        AnyCodable(self)
    }

    var encodable: AnyEncodable {
        AnyEncodable(self)
    }
    
    var flattened: [String: Any] {
        self.reduce(into: [String: Any](), { result, item in
            guard let dictionary = item.value as? [String: Any] else {
                result[item.key] = item.value
                return
            }
            result.merge(dictionary) { _, new  in new }
        })
    }
    
}


