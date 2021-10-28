//
//  AutotrackingConfigTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/10/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumAutotracking

class AutotrackingConfigTests: XCTestCase {

    func testWeakDelegate() throws {
        let config = TealiumConfig(account: "", profile: "", environment: "")
        var delegate: AutotrackingCollectorDelegate? = AutotrackingCollectorDelegate()
        config.autoTrackingCollectorDelegate = delegate
        XCTAssertNotNil(config.autoTrackingCollectorDelegate)
        XCTAssertTrue(config.autoTrackingCollectorDelegate! is AutotrackingCollectorDelegate)
        delegate = nil
        XCTAssertNil(config.autoTrackingCollectorDelegate)
    }

}

class AutotrackingCollectorDelegate: AutoTrackingDelegate {
    func onCollectScreenView(screenName: String) -> [String : Any] {
        return [:]
    }
}
