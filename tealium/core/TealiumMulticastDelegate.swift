//
//  TealiumUtils.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//
//

import Foundation

public class TealiumMulticastDelegate<T> {

    private var _weakDelegates = [Weak<AnyObject>]()

    public func add(_ delegate: T) {
        if Mirror(reflecting: delegate).subjectType is AnyClass {
            _weakDelegates.append(Weak(value: delegate as AnyObject))
        } else {
            fatalError("MulticastDelegate does not support value types")
        }
    }

    public func all() -> [Weak<AnyObject>] {
        return _weakDelegates
    }

    public func remove(_ delegate: T) {
        if type(of: delegate).self is AnyClass {
            _weakDelegates.remove(Weak(value: delegate as AnyObject))
        }
    }

    public func removeAll() {
        _weakDelegates.removeAll()
    }

    public var count: Int {
        return _weakDelegates.count
    }

    public func invoke(_ invocation: (T) -> Void) {
        for (_, delegate) in _weakDelegates.enumerated() {
            if let delegate = delegate.value {
                // swiftlint:disable force_cast
                invocation(delegate as! T)
                // swiftlint:enable force_cast
            }
        }
    }
}
