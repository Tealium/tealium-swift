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
        XCTAssertNotNil(actual[TealiumKey.sessionId])
        XCTAssertEqual(actual[TealiumKey.account] as! String, "testAccount")
        XCTAssertEqual(actual[TealiumKey.profile] as! String, "testProfile")
        XCTAssertEqual(actual[TealiumKey.environment] as! String, "testEnvironment")
        XCTAssertEqual(actual[TealiumKey.dataSource] as! String, "testDatasource")
        XCTAssertEqual(actual[TealiumKey.libraryName] as! String, "swift")

    }

    func testCurrentTimeStamps() {
        let timeStamps = eventDataManager.currentTimeStamps
        XCTAssertEqual(timeStamps.count, 5)
        let expectedKeys = [TealiumKey.timestampEpoch, TealiumKey.timestamp, TealiumKey.timestampLocal, TealiumKey.timestampUnixMilliseconds, TealiumKey.timestampUnix]
        let keys = timeStamps.map { $0.key }
        XCTAssertEqual(keys.sorted(), expectedKeys.sorted())
    }

    func testAddSessionData() {
        let sessionData: [String: Any] = ["hello": "session"]
        let eventDataItem = DataLayerItem(key: "hello", value: "session", expires: .distantFuture)
        eventDataManager.add(data: sessionData, expiry: .session)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "session")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }

    func testAddRestartData() {
        let restartData: [String: Any] = ["hello": "restart"]
        let eventDataItem = DataLayerItem(key: "hello", value: "restart", expires: .init(timeIntervalSinceNow: 60 * 60 * 12))
        eventDataManager.add(data: restartData, expiry: .untilRestart)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "restart")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }

    func testAddForeverData() {
        let foreverData: [String: Any] = ["hello": "forever"]
        let eventDataItem = DataLayerItem(key: "hello", value: "forever", expires: .distantFuture)
        eventDataManager.add(data: foreverData, expiry: .forever)
        XCTAssertNotNil(eventDataManager.all["hello"])
        XCTAssertEqual(eventDataManager.all["hello"] as! String, "forever")
        let retrieved = mockDiskStorage.retrieve(as: Set<DataLayerItem>.self)
        XCTAssertTrue(((retrieved?.contains(eventDataItem)) != nil))
    }

    func testCurrentTimeStampsExist() {
        var timeStamps = eventDataManager.currentTimeStamps
        timeStamps[TealiumKey.timestampOffset] = Date().timestampInSeconds
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
