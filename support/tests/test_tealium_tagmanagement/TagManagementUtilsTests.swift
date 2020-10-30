//
//  TagManagementUtilsTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
import XCTest

/// Can only test class level functions due to limitation of XCTest with WebViews
class TagManagementUtilsTests: XCTestCase {

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
