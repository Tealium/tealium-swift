//
//  MediaExtensions.swift
//  tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
//#if media
import TealiumCore
//#endif

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

public extension Encodable {
    /// - Returns: `[String: Any]` of `Codable` type
    var encoded: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any] }
    }
}

public extension Int {
    
    mutating func increment(by number: Int = 1) {
        self += number
    }
    
    mutating func decrement(by number: Int = 1) {
        self -= number
    }
}

