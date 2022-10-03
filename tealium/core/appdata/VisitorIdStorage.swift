//
//  VisitorIdStorage.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/10/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

struct VisitorIdStorage: Codable {
    private(set) var visitorId: String
    var currentIdentity: String?
    var cachedIds: [String: String]
    init(visitorId: String) {
        self.visitorId = visitorId
        cachedIds = [:]
    }
    mutating func setVisitorIdForCurrentIdentity(_ visitorId: String) {
        self.visitorId = visitorId
        setCurrentVisitorIdForCurrentIdentity()
    }
    mutating func setCurrentVisitorIdForCurrentIdentity() {
        if let identity = currentIdentity {
            cachedIds[identity] = visitorId
        }
    }
}
