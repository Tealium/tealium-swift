//
//  LifecycleExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

public extension Tealium {

    var lifecycle: LifecycleModule? {
        zz_internal_modulesManager?.modules.first {
            type(of: $0) == LifecycleModule.self
        } as? LifecycleModule
    }

}

public extension Collectors {
    static let Lifecycle = LifecycleModule.self
}

extension Bundle {
    var version: String? {
        return object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ??
            object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}

extension Array where Element == LifecycleSession {

    /// Get item before last
    ///
    /// - Returns: Target item or item at index 0 if only 1 item.
    var beforeLast: Element? {
        if self.isEmpty {
            return nil
        }

        var index = self.count - 2
        if index < 0 {
            index = 0
        }
        return self[index]
    }

}
