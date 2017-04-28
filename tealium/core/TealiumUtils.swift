//
//  TealiumUtils.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

class TealiumMulticastDelegate<T> {
    
    private var _weakDelegates = [Weak]()
    
    func add(_ delegate: T) {
        if Mirror(reflecting: delegate).subjectType is AnyClass {
            _weakDelegates.append(Weak(value: delegate as AnyObject))
        } else {
            fatalError("MulticastDelegate does not support value types")
        }
    }
    
    func remove(_ delegate: T) {
        if type(of: delegate).self is AnyClass {
            _weakDelegates.remove(Weak(value: delegate as AnyObject))
        }
    }
    
    func removeAll() {
        _weakDelegates.removeAll()
    }
    
    func invoke(_ invocation: (T) -> ()) {
        for (_, delegate) in _weakDelegates.enumerated() {
            if let delegate = delegate.value {
                invocation(delegate as! T)
            }
        }
    }

}

extension RangeReplaceableCollection where Iterator.Element : Equatable {
    @discardableResult
    mutating func remove(_ element : Iterator.Element) -> Iterator.Element? {
        if let index = self.index(of: element) {
            return self.remove(at: index)
        }
        return nil
    }
}

private class Weak: Equatable {
    weak var value: AnyObject?
    
    init(value: AnyObject) {
        self.value = value
    }
}

// Permits weak pointer collections
// Example Collection setup: var playerViewPointers = [String:Weak<PlayerView>]()
// Example Set: playerViewPointers[someKey] = Weak(value: playerView)
// Example Get: let x = playerViewPointers[user.uniqueId]?.value
//class Weak<T: AnyObject> {
//    weak var value : T?
//    init (value: T) {
//        self.value = value
//    }
//}

private func ==(lhs: Weak, rhs: Weak) -> Bool {
    return lhs.value === rhs.value
}


/**
 Extend the use of += operators to dictionaries.
 */
public func += <K, V> (left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

/**
 Extend use of == to dictionaries.
 */
public func ==(lhs: [String: Any], rhs: [String: Any] ) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}
