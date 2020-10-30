//
//  TealiumUtils.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    @discardableResult
    mutating func remove(_ element: Iterator.Element) -> Iterator.Element? {
        if let index = self.firstIndex(of: element) {
            return self.remove(at: index)
        }
        return nil
    }
}

// Permits weak pointer collections
// Example Collection setup: var playerViewPointers = [String:Weak<PlayerView>]()
// Example Set: playerViewPointers[someKey] = Weak(value: playerView)
// Example Get: let x = playerViewPointers[user.uniqueId]?.value
public class Weak<T: AnyObject>: Equatable {
    weak var value: T?

    init(value: T) {
        self.value = value
    }
}

public func == <T> (lhs: Weak<T>, rhs: Weak<T>) -> Bool {
    return lhs.value === rhs.value
}

/// Extend the use of += operators to dictionaries.
public func += <K, V> (left: inout [K: V], right: [K: V]) {
    for (key, value) in right {
        left.updateValue(value, forKey: key)
    }
}

/// Extend use of == to dictionaries.
public func == (lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

public extension Dictionary where Key == String, Value == Any {

    var codable: AnyCodable {
        return AnyCodable(self)
    }

    var encodable: AnyEncodable {
        return AnyEncodable(self)
    }
}
