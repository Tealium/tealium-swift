//
//  MediaExtensions.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if media
import TealiumCore
#endif

public extension Collectors {
    static let Media = MediaModule.self
}

public extension Tealium {
    /// - Returns: `MediaModule` instance
    var media: MediaModule? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == MediaModule.self
        } as? MediaModule)
    }
}

public extension TealiumConfig {
    
    /// Enables automatic tracking of `endSession` while the media player has been backgrounded longer than
    /// the  `backgroundMediaAutoEndSessionTime` (default `60.0` seconds)
    /// - Returns: `Bool` Default is `false`
    var enableBackgroundMediaTracking: Bool {
        get {
            options[TealiumKey.enableBackgroundMedia] as? Bool ?? false
        }
        set {
            options[TealiumKey.enableBackgroundMedia] = newValue
        }
    }
    
    /// Specifies the amount of time to wait before sending an `endSession` event once the app has been backgrounded
    /// - Returns: `Double` Default is `60.0` seconds
    var backgroundMediaAutoEndSessionTime: Double {
        get {
            options[TealiumKey.autoEndSesssionTime] as? Double ?? 60.0
        }
        set {
            options[TealiumKey.autoEndSesssionTime] = newValue
        }
    }

}

public extension Int {
    mutating func increment(by number: Int = 1) {
        self += number
    }
}

public extension Double {
    mutating func increment(by number: Double) {
        self += number
    }
}
