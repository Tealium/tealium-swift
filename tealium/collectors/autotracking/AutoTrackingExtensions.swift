//
//  AutoTrackingExtensions.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if autotracking
import TealiumCore
#endif

public extension Collectors {
    static let AutoTracking = AutotrackingModule.self
}

public extension TealiumConfig {

    var autoTrackingCollectorDelegate: AutoTrackingDelegate? {
        get {
            let weakDelegate = options[TealiumAutotrackingKey.delegate] as? Weak<AnyObject>
            return weakDelegate?.value as? AutoTrackingDelegate
        }

        set {
            var weakDelegate: Weak<AnyObject>?
            if let newValue = newValue {
                weakDelegate = Weak<AnyObject>(value: newValue)
            }
            options[TealiumAutotrackingKey.delegate] = weakDelegate
        }
    }

    var autoTrackingBlocklistFilename: String? {
        get {
            options[TealiumAutotrackingKey.filename] as? String
        }

        set {
            options[TealiumAutotrackingKey.filename] = newValue
        }
    }

    var autoTrackingBlocklistURL: String? {
        get {
            options[TealiumAutotrackingKey.url] as? String
        }

        set {
            options[TealiumAutotrackingKey.url] = newValue
        }
    }
}

enum TealiumAutotrackingKey {
    static let moduleName = "autotracking"
    static let viewNotificationName = "com.tealium.autotracking.view"
    static let autotracked = "autotracked"
    static let delegate = "delegate"
    static let filename = "filename"
    static let url = "url"

}

public protocol AutoTrackingDelegate: AnyObject {

    func onCollectScreenView(screenName: String) -> [String: Any]

}
