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

    /**
     * Creates parameters to be used with a `ResourceRefresher`.
     *
     * - parameters:
     *  - id: A unique String, used to identify the specific Refresher and the specific Resource it's refreshing.
     *  - url: The URL used to send the GET requests
     *  - fileName: the name used to store the resource on disk
     *  - refreshInterval: the interval in seconds used to refresh the resource after the initial refresh
     *  - errorCooldownBaseInterval: if present, it's the interval that is used, instead of the `refreshInterval`, in case of no resource found in the cache. It must be lower then `refreshInterval` if provided.
     */
    public init(id: String, url: URL, fileName: String?, refreshInterval: Double, errorCooldownBaseInterval: Double? = nil) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.refreshInterval = refreshInterval
        self.errorCooldownBaseInterval = errorCooldownBaseInterval
    }
}
