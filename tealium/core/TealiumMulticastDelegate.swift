//
//  TealiumUtils.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//
//  Build 2

// TODO: Rename as TealiumMulticastDelegate

import Foundation

class TealiumMulticastDelegate<T> {
    
    private var _weakDelegates = [Weak<AnyObject>]()
    
    func add(_ delegate: T) {
        if Mirror(reflecting: delegate).subjectType is AnyClass {
            _weakDelegates.append(Weak(value: delegate as AnyObject))
        } else {
            fatalError("MulticastDelegate does not support value types")
        }
    }
    
    func all() -> [Weak<AnyObject>] {
        return _weakDelegates
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
