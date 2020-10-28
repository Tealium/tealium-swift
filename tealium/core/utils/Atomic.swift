//
//  Atomic.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public final class Atomic<T> {
    private let lock = DispatchSemaphore(value: 1)
    private var _value: T

    public var value: T {
        get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            _value = newValue
        }
    }

    public init(value initialValue: T) {
        _value = initialValue
    }

    @discardableResult
    public func setAndGet(to value: T) -> T {
        lock.wait()
        defer { lock.signal() }
        _value = value
        return _value
    }
}
