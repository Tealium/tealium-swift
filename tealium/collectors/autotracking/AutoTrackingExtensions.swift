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
            TealiumInstanceManager.shared.autoTrackView(viewName: _wrapped.name)
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
    
    var autoTrackingBlocklistFilename: String? {
        get {
            options[TealiumAutotrackingKey.filename] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumAutotrackingKey.filename] = newValue
        }
    }
    
    var autoTrackingBlocklistURL: String? {
        get {
            options[TealiumAutotrackingKey.url] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumAutotrackingKey.url] = newValue
        }
    }
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
    static let filename = "filename"
    static let url = "url"
    
}

public protocol AutoTrackingDelegate: AnyObject {
    
    func onCollectScreenView(screenName: String) -> [String: Any]
    
}
