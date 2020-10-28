//
//  TealiumMulticastDelegate.swift
//  tealium-swift
//
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumMulticastDelegate<T> {

    private var _weakDelegates = [Weak<AnyObject>]()

    public init() {

    }

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
        if Mirror(reflecting: delegate).subjectType is AnyClass {

            _weakDelegates.remove(Weak(value: delegate as AnyObject))
        } else {
            fatalError("MulticastDelegate does not support value types")
        }
    }

    public func removeAll() {
        _weakDelegates.removeAll()
    }

    public var count: Int {
        return _weakDelegates.count
    }

    public func invoke(_ invocation: (T) -> Void) {
        let delegates = _weakDelegates
        // note: at time of writing, stepping into this triggers an LLDB crash
        // but the code functions fine and doesn't crash the app
        // Apple has fixed this in Xcode 10 beta after I logged this
        for (index, delegate) in delegates.enumerated().reversed() {
            if let delegate = delegate.value as? T {
                invocation(delegate)
            } else {
                _weakDelegates.remove(at: index)
            }
        }
    }
}
