//
//  Tealium+Encodable.swift
//  TealiumCore
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Encodable {
    /// - Returns: `[String: Any]` of `Codable` type
    var encoded: [String: Any]? {
        guard let data = try? Tealium.jsonEncoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any] }
    }
}
