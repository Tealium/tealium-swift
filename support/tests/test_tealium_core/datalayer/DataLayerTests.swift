//
//  DataLayerTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class DataLayerTests: XCTestCase {

    var mockDataLayerItem: DataLayerItem!
    var eventData: Set<DataLayerItem>!

    override func setUpWithError() throws {
        mockDataLayerItem = DataLayerItem(key: "itemOne", value: "test1", expiry: .forever)
        eventData = Set(arrayLiteral: mockDataLayerItem)
    }

    override func tearDownWithError() throws {
    }

    func testInsertSingle() {
        eventData.insert(key: "itemTwo", value: "test2", expiry: .forever)
        XCTAssertEqual(eventData.count, 2)
        XCTAssertTrue(eventData.isSubset(of: [mockDataLayerItem, DataLayerItem(key: "itemTwo", value: "test2", expiry: .forever)]))
    }

    func testInsertSingleExpires() {
        eventData = Set<DataLayerItem>()
        eventData.insert(key: "itemOne", value: "test1", expiry: .untilRestart)
        let eventDataExpired = eventData.removeExpired()
        XCTAssertEqual(eventDataExpired.count, 0)
    }

    func testInsertMulti() {
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expiry: .forever)
        XCTAssertEqual(eventData.count, 3)
        XCTAssertTrue(eventData.isSubset(of: [mockDataLayerItem, DataLayerItem(key: "itemTwo", value: "test2", expiry: .forever), DataLayerItem(key: "itemThree", value: "test3", expiry: .forever)]))
    }

    func testInsertMultiExpires() {
        eventData = Set<DataLayerItem>()
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expiry: .untilRestart)
        let eventDataExpired = eventData.removeExpired()
        XCTAssertEqual(eventDataExpired.count, 0)
    }

    func testRemove() {
        eventData.remove(key: "itemOne")
        XCTAssertEqual(eventData.count, 0)
    }

    func testGetAllData() {
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expiry: .forever)
        let expected: [String: Any] = ["itemOne": "test1", "itemTwo": "test2", "itemThree": "test3"]
        let actual = eventData.all
        XCTAssert(NSDictionary(dictionary: actual).isEqual(to: expected))
    }

}
