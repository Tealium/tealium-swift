//
//  MockTealiumVisitorServiceManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumVisitorService

public class MockTealiumVisitorServiceManager: VisitorServiceManagerProtocol {

    var startProfileUpdatesCount = 0
    var requestVisitorProfileCount = 0

    public func startProfileUpdates(visitorId: String) {
        startProfileUpdatesCount += 1
    }

    public func requestVisitorProfile() {
        requestVisitorProfileCount += 1
    }
}
