//
//  MediaExtensions.swift
//  tealium-swift
//
//  Created by Christina S on 1/11/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
// #if media
import TealiumCore
// #endif

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
