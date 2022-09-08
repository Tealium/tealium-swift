//
//  MockTealiumVisitorServiceManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumVisitorService

public class MockTealiumVisitorServiceManager: VisitorServiceManagerProtocol {
    public var currentVisitorId: String?
    
    public var cachedProfile: TealiumVisitorProfile?
    
    var requestVisitorProfileCount = 0

    public func requestVisitorProfile() {
        requestVisitorProfileCount += 1
    }
}
