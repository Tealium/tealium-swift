//
//  DataLayerManagerTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class DataLayerManagerTests: XCTestCase {

    var config: TealiumConfig!
    var eventDataManager: DataLayer!
    var mockDiskStorage: TealiumDiskStorageProtocol!
    var mockSessionStarter: SessionStarter!
    var tealium: Tealium?

    override func setUpWithError() throws {
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment", dataSource: "testDatasource")
        mockDiskStorage = MockDataLayerDiskStorage()
        mockSessionStarter = SessionStarter(config: config, urlSession: MockURLSessionSessionStarter())
        eventDataManager = DataLayer(config: config, diskStorage: mockDiskStorage, sessionStarter: mockSessionStarter)
        TealiumQueues.backgroundSerialQueue.sync {
            print("") // just wait for session to be started
        }
    }

    override func tearDownWithError() throws {
    }

    func testInitSetsStaticData() {
        let expected: [String: Any] = ["timestamp": "2020-05-04T23:05:51Z",
                                       "timestamp_unix": "1588633551",
                                       "tealium_session_id": "1588633455745",
                                       "tealium_timestamp_epoch": "1588633551",
                                       "timestamp_offset": "-7",
                                       "tealium_account": "testAccount",
                                       "tealium_environment": "testEnvironment",
                                       "tealium_library_version": "1.10.0",
                                       "tealium_profile": "testProfile",
                                       "timestamp_local": "2020-05-04T16:05:51",
                                       "tealium_library_name": "swift",
                                       "timestamp_unix_milliseconds": "1588633551183",
                                       "tealium_random": "4",
                                       "singleDataItemKey1": "singleDataItemValue1",
                                       "singleDataItemKey2": "singleDataItemValue2",
                                       "tealium_datasource": "testDatasource",
                                       "origin": "mobile"]
        let actual = eventDataManager.all
        XCTAssertEqual(actual.count, expected.count)
        XCTAssertEqual(actual.keys.sorted(), expected.keys.sorted())
        XCTAssertNotNil(actual[TealiumDataKey.sessionId])
        XCTAssertEqual(actual[TealiumDataKey.account] as! String, "testAccount")
        XCTAssertEqual(actual[TealiumDataKey.profile] as! String, "testProfile")
        XCTAssertEqual(actual[TealiumDataKey.environment] as! String, "testEnvironment")
        XCTAssertEqual(actual[TealiumDataKey.dataSource] as! String, "testDatasource")
        XCTAssertEqual(actual[TealiumDataKey.libraryName] as! String, "swift")

    }

    func testCurrentTimeStamps() {
        let timeStamps = eventDataManager.currentTimeStamps
        XCTAssertEqual(timeStamps.count, 5)
        let expectedKeys = [TealiumDataKey.timestampEpoch, TealiumDataKey.timestamp, TealiumDataKey.timestampLocal, TealiumDataKey.timestampUnixMilliseconds, TealiumDataKey.timestampUnix]
        let keys = timeStamps.map { $0.key }
        XCTAssertEqual(keys.sorted(), expectedKeys.sorted())
    }

    func testAddSessionData() {
        let sessionData: [String: Any] = ["hello": "session"]
        let eventDataItem = DataLayerItem(key: "hello", value: "session", expiry: .session)
        eventDataManager.add(data: sessionData, expiry: .session)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "session")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertNotNil(retrieved)
        XCTAssertTrue(retrieved!.contains(eventDataItem))
    }
    
    func testResetSessionData() {
        let sessionData: [String: Any] = ["hello": "session"]
        eventDataManager.add(data: sessionData, expiry: .session)
        XCTAssertNotNil(eventDataManager.all["hello"])
        let id = eventDataManager.sessionId
        XCTAssertNotNil(eventDataManager.sessionId)
        let exp = expectation(description: "wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(2)) { // Required a little delay otherwise sessions may have the same id due to the same millisecond
            self.eventDataManager.refreshSessionData()
            XCTAssertNotEqual(id, self.eventDataManager.sessionId)
            XCTAssertNil(self.eventDataManager.all["hello"])
            exp.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAddRestartData() {
        let restartData: [String: Any] = ["hello": "restart"]
        let eventDataItem = DataLayerItem(key: "hello", value: "restart", expiry: .afterCustom((.hours, 12)))
        eventDataManager.add(data: restartData, expiry: .untilRestart)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "restart")
        let retrieved = self.mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }
    
    func testDeleteRestartData() {
        let restartData: [String: Any] = ["1": "1", "2":"2", "3": "3"]
        eventDataManager.add(data: restartData, expiry: .untilRestart)
        let count = eventDataManager.all.count
        // Delete restart data
        eventDataManager.delete(for: "1")
        XCTAssertEqual(eventDataManager.all.count, count-1)
        eventDataManager.delete(for: ["2", "3"])
        XCTAssertEqual(eventDataManager.all.count, count-3)
    }

    func testAddForeverData() {
        let foreverData: [String: Any] = ["hello": "forever"]
        let eventDataItem = DataLayerItem(key: "hello", value: "forever", expiry: .forever)
        eventDataManager.add(data: foreverData, expiry: .forever)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "forever")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }

    func testCurrentTimeStampsExist() {
        var timeStamps = eventDataManager.currentTimeStamps
        timeStamps[TealiumDataKey.timestampOffset] = Date().timestampInSeconds
        XCTAssertTrue(eventDataManager.currentTimestampsExist(timeStamps))
    }

    func testCurrentTimeStampsDontExist() {
        XCTAssertFalse(eventDataManager.currentTimestampsExist([String: Any]()))
    }

    func testDeleteForKeys() {
        eventDataManager.delete(for: ["singleDataItemKey1", "singleDataItemKey2"])
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertEqual(retrieved?.count, 1)
    }

    func testDeleteForKey() {
        eventDataManager.delete(for: "singleDataItemKey1")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertEqual(retrieved?.count, 2)
    }

    func testDeleteAll() {
        eventDataManager.deleteAll()
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertEqual(retrieved?.count, 0)
    }
    
    func testFilterKeysInDataLayer() {
        eventDataManager.deleteAll()
        eventDataManager.add(key: "someRestart", value: "value", expiry: .untilRestart)
        eventDataManager.add(key: "somePersistent", value: "value", expiry: .forever)
        let keys = eventDataManager.filterKeysInDataLayer(["somePersistent", "someRestart", "nonPresent"])
        XCTAssertEqual(keys, ["somePersistent", "someRestart"])
    }

    func testSendRemovedEventNotTriggered() {
        let expect = expectation(description: "Data is not removed for empty keys")
        expect.isInverted = true
        let sub = eventDataManager.onDataRemoved.subscribe { _ in
            expect.fulfill()
        }
        let removed = eventDataManager.sendRemovedEvent(forKeys: [])
        XCTAssertFalse(removed)
        waitForExpectations(timeout: 2)
        sub.dispose()
    }

    func testSendRemovedEventTriggered() {
        let expect = expectation(description: "Data is not removed for empty keys")
        let sub = eventDataManager.onDataRemoved.subscribe { _ in
            expect.fulfill()
        }
        let removed = eventDataManager.sendRemovedEvent(forKeys: ["someKey"])
        XCTAssertTrue(removed)
        waitForExpectations(timeout: 2)
        sub.dispose()
    }

    func testExpiredItems() {
        let key = "expired"
        let expect = expectation(description: "Data is removed")
        eventDataManager.onDataRemoved.subscribe { removedKeys in
            XCTAssertTrue(removedKeys.contains(key))
            expect.fulfill()
        }
        eventDataManager.add(key: key, value: "any", expiry: .after(Date()))
        XCTAssertFalse(eventDataManager.all.keys.contains(key))
        waitForExpectations(timeout: 2)
    }

    //    func testAddPersistendDataFromBackgroundThread() {
    //        let expect = expectation(description: "testAddPersistendDataFromBackgroundThread")
    //        config.shouldUseRemotePublishSettings = false
    //        config.batchingEnabled = false
    //        tealium = Tealium(config: config)
    //        tealium?.dataLayer.deleteAll()
    //
    //        for i in 0...100 {
    //            DispatchQueue.global(qos: .background).async {
    //                self.tealium?.dataLayer.add(data: ["testkey\(i)": "testval"], expiry: .forever)
    //            }
    //        }
    //
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
    //            let data = self.tealium?.dataLayer.all
    //            expect.fulfill()
    //            self.largeDataSet.forEach {
    //                XCTAssertNotNil(data![$0.key], "Expected data missing: \($0.key)")
    //            }
    //        }
    //
    //        wait(for: [expect], timeout: 20)
    //    }

    //    func testDeletePersistentDataFromBackgrounThread() {
    //        let expect = expectation(description: "testDeletePersistentDataFromBackgrounThread")
    //        config.shouldUseRemotePublishSettings = false
    //        config.batchingEnabled = false
    //        tealium = Tealium(config: config)
    //        tealium?.dataLayer.deleteAll()
    //
    //        for i in 0...100 {
    //            self.tealium?.dataLayer.add(data: ["testkey\(i)": "testval"], expiry: .forever)
    //        }
    //
    //        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10.0) {
    //            for i in 0...100 {
    //                self.tealium?.dataLayer.delete(for: "testkey\(i)")
    //            }
    //            let data = self.tealium?.dataLayer.all
    //            expect.fulfill()
    //            self.largeDataSet.forEach {
    //                XCTAssertNil(data![$0.key], "Expected data missing: \($0.key)")
    //            }
    //        }
    //
    //        wait(for: [expect], timeout: 20)
    //    }
    //
    //    func testAddPersistendDataFromUtilityThread() {
    //        let expect = expectation(description: "testAddPersistendDataFromUtilityThread")
    //        config.shouldUseRemotePublishSettings = false
    //        config.batchingEnabled = false
    //        tealium = Tealium(config: config)
    //        tealium?.dataLayer.deleteAll()
    //
    //        for i in 0...100 {
    //            DispatchQueue.global(qos: .utility).async {
    //                self.tealium?.dataLayer.add(data: ["testkey\(i)": "testval"], expiry: .forever)
    //            }
    //        }
    //
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
    //            let data = self.tealium?.dataLayer.all
    //            expect.fulfill()
    //            self.largeDataSet.forEach {
    //                XCTAssertNotNil(data![$0.key], "Expected data missing: \($0.key)")
    //            }
    //        }
    //
    //        wait(for: [expect], timeout: 20)
    //    }

}

//extension DataLayerManagerTests {
//
//    var largeDataSet: [String: Any] {
//        var dictionary = [String: Any]()
//        for i in 1...100 {
//            dictionary["testkey\(i)"] = "testval"
//        }
//        return dictionary
//    }
//
//}
