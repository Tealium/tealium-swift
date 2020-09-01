//
//  DataLayerTests.swift
//  TealiumCoreTests
//
//  Created by Christina S on 5/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class DataLayerTests: XCTestCase {

    var mockDataLayerItem: DataLayerItem!
    var eventData: DataLayerCollection!

    override func setUpWithError() throws {
        mockDataLayerItem = DataLayerItem(key: "itemOne", value: "test1", expires: .distantFuture)
        eventData = Set(arrayLiteral: mockDataLayerItem)
    }

    override func tearDownWithError() throws {
    }

    func testInsertSingle() {
        eventData.insert(key: "itemTwo", value: "test2", expires: .distantFuture)
        XCTAssertEqual(eventData.count, 2)
        XCTAssertTrue(eventData.isSubset(of: [mockDataLayerItem, DataLayerItem(key: "itemTwo", value: "test2", expires: .distantFuture)]))
    }

    func testInsertSingleExpires() {
        eventData = DataLayerCollection()
        eventData.insert(key: "itemOne", value: "test1", expires: .distantPast)
        let eventDataExpired = eventData.removeExpired()
        XCTAssertEqual(eventDataExpired.count, 0)
    }

    func testInsertMulti() {
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expires: .distantFuture)
        XCTAssertEqual(eventData.count, 3)
        XCTAssertTrue(eventData.isSubset(of: [mockDataLayerItem, DataLayerItem(key: "itemTwo", value: "test2", expires: .distantFuture), DataLayerItem(key: "itemThree", value: "test3", expires: .distantFuture)]))
    }

    func testInsertMultiExpires() {
        eventData = DataLayerCollection()
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expires: .distantPast)
        let eventDataExpired = eventData.removeExpired()
        XCTAssertEqual(eventDataExpired.count, 0)
    }

    func testRemove() {
        eventData.remove(key: "itemOne")
        XCTAssertEqual(eventData.count, 0)
    }

    func testGetAllData() {
        let multi = ["itemTwo": "test2", "itemThree": "test3"]
        eventData.insert(from: multi, expires: .distantFuture)
        let expected: [String: Any] = ["itemOne": "test1", "itemTwo": "test2", "itemThree": "test3"]
        let actual = eventData.all
        XCTAssert(NSDictionary(dictionary: actual).isEqual(to: expected))
    }

}
