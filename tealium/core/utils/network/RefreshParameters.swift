//
//  RefreshParameters.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 05/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol EtagResource {
    var etag: String? { get }
}

public struct RefreshParameters<Resource> {
    let id: String
    let url: URL
    let fileName: String?
    var refreshInterval: Double
    let errorCooldownBaseInterval: Double?
    public init(id: String, url: URL, fileName: String?, refreshInterval: Double, errorCooldownBaseInterval: Double? = nil) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.refreshInterval = refreshInterval
        self.errorCooldownBaseInterval = errorCooldownBaseInterval
    }
}
