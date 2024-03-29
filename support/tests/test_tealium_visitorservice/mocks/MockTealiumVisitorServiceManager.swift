//
//  MockTealiumVisitorServiceManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumVisitorService

public class MockTealiumVisitorServiceManager: VisitorServiceManagerProtocol {
    public var lastFetch: Date?
    
    public var currentVisitorId: String? = "initialId"
    
    public var cachedProfile: TealiumVisitorProfile?
    
    var requestVisitorProfileCount = 0

    public func requestVisitorProfile() {
        requestVisitorProfileCount += 1
        lastFetch = Date()
    }
}
