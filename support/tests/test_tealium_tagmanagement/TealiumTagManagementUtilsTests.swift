//
//  TealiumTagManagementTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

/// Can only test class level functions due to limitation of XCTest with WebViews
class TealiumTagManagementUtilsTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testGetLegacyTypeView() {
        let eventType = "call_type"
        let viewValue = "view"
        let viewDictionary: [String: Any] = [eventType: viewValue]
        let viewResult = viewDictionary.legacyType

        XCTAssertTrue(viewResult == viewValue)
    }

    func testGetLegacyTypeEvent() {
        let eventType = "call_type"
        let linkValue = "link"
        let eventDictionary: [String: Any] = [eventType: linkValue]
        let eventResult = eventDictionary.legacyType

        XCTAssertTrue(eventResult == "link")
    }

    func testRandomEventType() {
        let eventType = "call_type"
        let anyValue = "any"
        let eventDictionary: [String: Any] = [eventType: anyValue]
        let eventResult = eventDictionary.legacyType

        XCTAssertTrue(eventResult == anyValue)
    }
}
