//
//  URL+Tealium.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 22/07/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public extension URL {
    func appendingQueryItems(_ params: [URLQueryItem]) -> URL {
        guard !params.isEmpty,
            var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        var items = components.queryItems ?? []
        items.append(contentsOf: params)
        components.queryItems = items
        return components.url ?? self
    }
}
