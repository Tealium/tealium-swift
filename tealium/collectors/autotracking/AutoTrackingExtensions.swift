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

@propertyWrapper
public class AutoTracked {

    private var value: String
    private var track: Bool
    
    public var wrappedValue: String {
        get {
            let notification = ViewNotification.forView(value)
            TealiumQueues.backgroundSerialQueue.asyncAfter(deadline: .now() + 0.1) {
                if self.track {
                    NotificationCenter.default.post(notification)
                }
            }
            return value
        }
        
        set {
            value = newValue
        }
    }

    public init(wrappedValue: String,
                _ track: Bool = true) {
        self.value = wrappedValue
        self.track = track
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

public protocol AutoTrackingDelegate: class {
    
    func onCollectScreenView(screenName: String) -> [String: Any]
    
}

