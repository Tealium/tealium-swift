//
//  TealiumConstantsTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumConstantsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConstantsStrings() {
        XCTAssertTrue(TealiumTrackType.view.description == "view")
        XCTAssertTrue(TealiumTrackType.event.description == "event")
    }

}
