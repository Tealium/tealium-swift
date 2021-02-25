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

@propertyWrapper public class AutoTracked {

    private var _wrapped: (name: String, track: Bool) = ("", false)
    
    public var wrappedValue: (name: String, track: Bool) {
        get {
            print("View: \(_wrapped)")
            return _wrapped
        }
        
        set {
            _wrapped = newValue
        }
        
    }

    public init(wrappedValue: (name: String, track: Bool)) {
        self.wrappedValue = wrappedValue
    }
}


public extension TealiumConfig {
    
    var autoTrackingCollectorDelegate: AutoTrackingDelegate? {
        get {
            options[TealiumAutotrackingKey.delegate] as? AutoTrackingDelegate
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumAutotrackingKey.delegate] = newValue
        }
    }
    
    var autoTrackingMode: AutoTrackingMode? {
        get {
            options[TealiumAutotrackingKey.mode] as? AutoTrackingMode
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumAutotrackingKey.mode] = newValue
        }
    }
    
//    var autoTrackingBlocklistFilename: String? {
//
//    }
    
//    var autoTrackingBlocklistURL: String? {
//
//    }
}

public enum AutoTrackingMode {
    case full
    case annotated
    case viewWrapper
    case disabled
}


enum TealiumAutotrackingKey {
    static let moduleName = "autotracking"
    static let viewNotificationName = "com.tealium.autotracking.view"
    static let autotracked = "autotracked"
    static let delegate = "delegate"
    static let mode = "mode"
    
}

public protocol AutoTrackingDelegate: class {
    
    func onCollectScreenView(screenName: String) -> [String: Any]
    
}
