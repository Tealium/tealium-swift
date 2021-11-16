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

extension TealiumConfigKey {
    static let autotrackingDelegate = "delegate"
    static let autotrackingFilename = "filename"
    static let autotrackingUrl = "url"
}

public extension TealiumConfig {

    var autoTrackingCollectorDelegate: AutoTrackingDelegate? {
        get {
            let weakDelegate = options[TealiumConfigKey.autotrackingDelegate] as? Weak<AnyObject>
            return weakDelegate?.value as? AutoTrackingDelegate
        }

        set {
            var weakDelegate: Weak<AnyObject>?
            if let newValue = newValue {
                weakDelegate = Weak<AnyObject>(value: newValue)
            }
            options[TealiumConfigKey.autotrackingDelegate] = weakDelegate
        }
    }

    var autoTrackingBlocklistFilename: String? {
        get {
            options[TealiumConfigKey.autotrackingFilename] as? String
        }

        set {
            options[TealiumConfigKey.autotrackingFilename] = newValue
        }
    }

    var autoTrackingBlocklistURL: String? {
        get {
            options[TealiumConfigKey.autotrackingUrl] as? String
        }

        set {
            options[TealiumConfigKey.autotrackingUrl] = newValue
        }
    }
}

public extension TealiumDataKey {
    static let autotracked = "autotracked"
}

enum TealiumAutotrackingKey {
    static let moduleName = "AutoTracking"
}

public protocol AutoTrackingDelegate: AnyObject {
    func onCollectScreenView(screenName: String) -> [String: Any]
}
