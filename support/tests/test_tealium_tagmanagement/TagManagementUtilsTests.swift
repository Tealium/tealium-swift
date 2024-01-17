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
        let eventType = "tealium_event_type"
        let viewValue = "view"
        let viewDictionary: [String: Any] = [eventType: viewValue]
        let viewResult = viewDictionary.legacyType

        XCTAssertTrue(viewResult == viewValue)
    }

    func testGetLegacyTypeEvent() {
        let eventType = "tealium_event_type"
        let linkValue = "link"
        let eventDictionary: [String: Any] = [eventType: linkValue]
        let eventResult = eventDictionary.legacyType

        XCTAssertTrue(eventResult == "link")
    }

    func testRandomEventType() {
        let eventType = "tealium_event_type"
        let anyValue = "any"
        let eventDictionary: [String: Any] = [eventType: anyValue]
        let eventResult = eventDictionary.legacyType

        XCTAssertTrue(eventResult == anyValue)
    }

    func testDispatchGroupTimeout() {
        let expectation = expectation(description: "Group notifies after timeout")
        let group = DispatchGroup()
        group.enter()
        group.tealiumNotify(queue: .main, timeout: 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }

    func testTagManagementErrorLocalizedDescription() {
        let error: Error = TagManagementError.unknownDispatchError
        XCTAssertEqual(error.localizedDescription, "TagManagementError.unknownDispatchError")
    }

    func testWebViewErrorLocalizedDescription() {
        let error: Error = WebviewError.webviewNotInitialized
        XCTAssertEqual(error.localizedDescription, "WebviewError.webviewNotInitialized")
    }
}
