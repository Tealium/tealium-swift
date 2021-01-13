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

public func ==<T>(lhs: Weak<T>, rhs: Weak<T>) -> Bool {
    return lhs.value === rhs.value
}


