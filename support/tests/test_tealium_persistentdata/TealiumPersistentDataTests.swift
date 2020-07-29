//
//  TealiumPersistentDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumPersistentData
import XCTest

class TealiumPersistentDataTests: XCTestCase {

    var loadExpectation: XCTestExpectation?
    var saveExpectation: XCTestExpectation?
    var testData: [String: Any]?
    var persistentData: TealiumPersistentData?
    var loadCompletion: TealiumCompletion?
    var loadShouldSucceed: Bool = false
    var tealium: Tealium?
    static let testPersistentData = ["key": "value",
                                           "anotherKey": "anotherValue"]

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        testData = nil
        loadExpectation = nil
        saveExpectation = nil
        persistentData = nil
        loadCompletion = nil
        super.tearDown()
    }

    func testSetExistingLegacyData() {
        // use disk storage with saved data
        // init persistent data
        // check that expected data is in persistent data

        let diskStorage = PersistentDataMockDiskStorage()
        persistentData = TealiumPersistentData(diskStorage: diskStorage, legacyMigrator: MockTealiumMigratorWithData.self)

        let targetKeys = ["key", "anotherKey"]

        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        targetKeys.forEach { key in
            XCTAssertNotNil(cache.values()![key], "Expected data missing: \(key)")
        }
    }

    func testSetExistingNoLegacyData() {
        // use disk storage with saved data
        // init persistent data
        // check that expected data is in persistent data

        let diskStorage = PersistentDataMockDiskStorage()
        var persistentDataStore = TealiumPersistentDataStorage()
        let persistentKey = "newKey"
        persistentDataStore.add(data: [persistentKey: "persistent"])
        diskStorage.save(persistentDataStore, completion: nil)
        persistentData = TealiumPersistentData(diskStorage: diskStorage, legacyMigrator: MockTealiumMigratorNoData.self)

        let targetKeys = ["key", "anotherKey"]

        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        targetKeys.forEach { key in
            XCTAssertNil(cache.values()![key], "Unexpected data: \(key)")
        }
        XCTAssertNotNil(cache.values()![persistentKey], "Missing expected value: \(persistentKey)")
    }

    func testAddData() {
        let diskStorage = PersistentDataMockDiskStorage()
        persistentData = TealiumPersistentData(diskStorage: diskStorage)

        let targetKey = "key"
        var expectedData = TealiumPersistentDataStorage()
        expectedData.add(data: TealiumPersistentDataTests.testPersistentData)

        persistentData?.persistentDataCache = expectedData
        persistentData?.deleteData(forKeys: [targetKey])

        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        XCTAssertNotNil(cache.values()!["anotherKey"], "Expected data missing: anotherKey")
        XCTAssertNil(cache.values()![targetKey], "Unexpected persistent data: \(targetKey)")
    }

    func testRemoveDataForKeys() {
        let diskStorage = PersistentDataMockDiskStorage()
        persistentData = TealiumPersistentData(diskStorage: diskStorage)

        let targetKey = "key"
        var expectedData = TealiumPersistentDataStorage()
        expectedData.add(data: TealiumPersistentDataTests.testPersistentData)

        persistentData?.persistentDataCache = expectedData
        persistentData?.deleteData(forKeys: [targetKey])

        guard let cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        XCTAssertNotNil(cache.values()!["anotherKey"], "Expected data missing: anotherKey")
        XCTAssertNil(cache.values()![targetKey], "Unexpected persistent data: \(targetKey)")
    }

    func testDeleteAllData() {
        let diskStorage = PersistentDataMockDiskStorage()
        persistentData = TealiumPersistentData(diskStorage: diskStorage)

        persistentData?.add(data: TealiumPersistentDataTests.testPersistentData)
        persistentData?.deleteAllData()

        // Check cache
        guard var cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        guard cache.isEmpty else {
            XCTFail("Cache unexpectedly not empty.")
            return
        }

        let data = diskStorage.retrieve(as: TealiumPersistentDataStorage.self)
        XCTAssertNil(data)
    }
    
    func testGetDictionary() {
        let diskStorage = PersistentDataMockDiskStorage()
        persistentData = TealiumPersistentData(diskStorage: diskStorage)

        persistentData?.add(data: TealiumPersistentDataTests.testPersistentData)
        
        // Check cache
        guard var cache = persistentData?.persistentDataCache else {
            XCTFail("Cache unexpectedly nil.")
            return
        }

        guard !cache.isEmpty else {
            XCTFail("Cache unexpectedly empty.")
            return
        }
        
        let data = persistentData?.dictionary
        data?.forEach {
            XCTAssertNotNil(data![$0.key], "Expected data missing: \($0.key)")
        }
    }

    func testAddPersistendDataFromBackgroundThread() {
        saveExpectation = expectation(description: "testAddPersistendDataFromBackgroundThread")
        testTealiumConfig.shouldUseRemotePublishSettings = false
        testTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: testTealiumConfig) { [weak self] _ in
            self?.tealium?.persistentData()?.deleteAllData()
            for i in 0...100 {
                DispatchQueue.global(qos: .background).async {
                    self?.tealium?.persistentData()?.add(data: ["testkey\(i)": "testval"])
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            let data = self.tealium?.persistentData()?.dictionary
            self.saveExpectation?.fulfill()
            self.largeDataSet.forEach {
                XCTAssertNotNil(data![$0.key], "Expected data missing: \($0.key)")
            }
        }

        wait(for: [saveExpectation!], timeout: 20)
    }

    func testAddPersistendDataFromUtilityThread() {
        saveExpectation = expectation(description: "testAddPersistendDataFromUtilityThread")
        testTealiumConfig.shouldUseRemotePublishSettings = false
        testTealiumConfig.batchingEnabled = false
        tealium = Tealium(config: testTealiumConfig) { [weak self] _ in
            self?.tealium?.persistentData()?.deleteAllData()
            for i in 0...100 {
                DispatchQueue.global(qos: .utility).async {
                    self?.tealium?.persistentData()?.add(data: ["testkey\(i)": "testval"])
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            let data = self.tealium?.persistentData()?.dictionary
            self.saveExpectation?.fulfill()
            self.largeDataSet.forEach {
                XCTAssertNotNil(data![$0.key], "Expected data missing: \($0.key)")
            }
        }

        wait(for: [saveExpectation!], timeout: 20)
    }

}

extension TealiumPersistentDataTests {

    var largeDataSet: [String: Any] {
        var dictionary = [String: Any]()
        for i in 1...100 {
            dictionary["testkey\(i)"] = "testval"
        }
        return dictionary
    }

}
