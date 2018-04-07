//
//  TealiumPersistentDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumPersistentDataTests: XCTestCase {

    var loadExpectation: XCTestExpectation?
    var saveExpectation: XCTestExpectation?
    var testData: [String: Any]?
    var persistentData: TealiumPersistentData?
    var loadCompletion: TealiumCompletion?
    var loadShouldSucceed: Bool = false

    override func setUp() {
        super.setUp()

        persistentData = TealiumPersistentData(delegate: self)
    }

    override func tearDown() {
        testData = nil
        loadExpectation = nil
        saveExpectation = nil
        persistentData = nil
        loadCompletion = nil
        super.tearDown()
    }

    func testInitWithAutoLoadRequestWithPriorData() {
        loadExpectation = self.expectation(description: "autoLoad")
        testData = ["key": "value"]
        loadShouldSucceed = true

        let persistentData = TealiumPersistentData(delegate: self)
        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssert(persistentData.persistentDataCache == testData!, "Unexpected data loaded: \(persistentData.persistentDataCache)")

    }

    func testInitWithAutoLoadRequestWithNoPriorData() {
        loadExpectation = self.expectation(description: "autoLoad")
        loadShouldSucceed = true

        let persistentData = TealiumPersistentData(delegate: self)
        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssert(persistentData.persistentDataCache.isEmpty, "Unexpected data loaded: \(persistentData.persistentDataCache)")

    }

    func testAddData() {
        saveExpectation = self.expectation(description: "addData")
        let expectedData = ["key": "value"]

        persistentData?.add(data: expectedData)
        self.waitForExpectations(timeout: 1.0, handler: nil)

        // Check cache
        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache did not retain data.")
            return
        }

        if cache.isEmpty {
            XCTFail("Cache unexpectedly empty.")
        }

        guard let results = testData else {
            XCTFail("Test Data unexpectedly empty.")
            return
        }

        XCTAssert(expectedData == results, "Unexpected saved data: \(results)")
    }

    func testRemoveDataForKeys() {
        saveExpectation = self.expectation(description: "removeData")
        let targetKey = "key"
        let expectedData = [targetKey: "value"]

        persistentData?.persistentDataCache = expectedData
        persistentData?.deleteData(forKeys: [targetKey])

        self.waitForExpectations(timeout: 1.0, handler: nil)

        // Check cache
        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        if cache.isEmpty == false {
            XCTFail("Cache unexpectedly not empty.")
        }

        guard let results = testData else {
            XCTFail("Test Data unexpectedly nil.")
            return
        }

        XCTAssert(results.isEmpty, "Unexpected persistent data: \(results)")
    }

    func testDeleteAllData() {
        saveExpectation = self.expectation(description: "removeData")
        let expectedData = ["key": "value",
                            "anotherKey": "anotherValue"]

        persistentData?.persistentDataCache = expectedData
        persistentData?.deleteAllData()

        self.waitForExpectations(timeout: 1.0, handler: nil)

        // Check cache
        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        if cache.isEmpty == false {
            XCTFail("Cache unexpectedly not empty.")
        }

        guard let results = testData else {
            XCTFail("Test Data unexpectedly nil.")
            return
        }

        XCTAssert(results.isEmpty, "Unexpected persistent data: \(results)")
    }

}

extension TealiumPersistentDataTests: TealiumPersistentDataDelegate {

    func requestSave(data: [String: Any]) {
        testData = data
        saveExpectation?.fulfill()
    }

    func requestLoad(completion: @escaping TealiumCompletion) {
        if loadShouldSucceed {
            completion(true, testData, nil)
        } else {
            completion(false, testData, nil)
        }
        loadExpectation?.fulfill()
    }
}
