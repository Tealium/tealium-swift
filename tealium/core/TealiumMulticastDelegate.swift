//
//  TealiumUtils.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//
//  Build 3

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
    
    public func invoke(_ invocation: (T) -> ()) {
        for (_, delegate) in _weakDelegates.enumerated() {
            if let delegate = delegate.value {
                invocation(delegate as! T)
            }
        }
    }

}
