//
//  AutoTrackingExtensions.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if autotracking
import TealiumCore
#endif

public extension Collectors {
    static let AutoTracking = AutotrackingModule.self
}
#endif

class TealiumAutoTracking {

}

@propertyWrapper public class AutoTracked {

    private var _wrapped: String = ""
    
    public var wrappedValue: String {
        get {
            print("View: \(_wrapped)")
            return _wrapped
        }
        
        set {
            _wrapped = newValue
        }
        
    }

    public init(wrappedValue: String) {
        self.wrappedValue = wrappedValue
    }
}

