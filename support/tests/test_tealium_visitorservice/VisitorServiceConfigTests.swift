//
//  VisitorServiceConfigTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumVisitorService

class VisitorServiceConfigTests: XCTestCase {
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testWeakDelegate() throws {
        let config = TealiumConfig(account: "", profile: "", environment: "")
        var delegate: VisitorDelegate? = VisitorDelegate()
        config.visitorServiceDelegate = delegate
        XCTAssertNotNil(config.visitorServiceDelegate)
        XCTAssertTrue(config.visitorServiceDelegate! is VisitorDelegate)
        delegate = nil
        XCTAssertNil(config.visitorServiceDelegate)
    }

}


class VisitorDelegate: VisitorServiceDelegate {
    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        
    }
    
}
