//
//  AppDataModuleTests.swift
//  tealium-swift
//
//  Created by Christina S on 05/20/20.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class AppDataModuleTests: XCTestCase {

    var appDataModule: AppDataModule?
    let mockDiskStorage = MockAppDataDiskStorage()

    override func setUp() {
        appDataModule = AppDataModule(config: TestTealiumHelper().getConfig(), delegate: self, diskStorage: mockDiskStorage, bundle: Bundle(for: type(of: self)))
    }

    func testInitSetsExistingAppData() {
        XCTAssertEqual(mockDiskStorage.retrieveCount, 1)
        guard let data = appDataModule?.data, let visId = data[TealiumKey.visitorId] as? String else {
            XCTFail("Nothing in persistent app data and there should be a test visitor id.")
            return
        }
        XCTAssertEqual(visId, "someVisitorId")
    }

    func testDeleteAllData() {
        appDataModule?.deleteAll()
        XCTAssertEqual(mockDiskStorage.deleteCount, 1)
    }

    func testIsMissingPersistentKeys() {
        let missingUUID = [TealiumKey.visitorId: "someVisitorId"]
        XCTAssertTrue(AppDataModule.isMissingPersistentKeys(data: missingUUID))
        let missingVisitorID = [TealiumKey.uuid: "someUUID"]
        XCTAssertTrue(AppDataModule.isMissingPersistentKeys(data: missingVisitorID))
        let neitherMissing = [TealiumKey.visitorId: "someVisitorId", TealiumKey.uuid: "someUUID"]
        XCTAssertFalse(AppDataModule.isMissingPersistentKeys(data: neitherMissing))
    }

    func testVisitorIdFromUUID() {
        let uuid = UUID().uuidString
        guard let visitorId = appDataModule?.visitorId(from: uuid) else {
            XCTFail("Visitor id should not be null")
            return
        }
        XCTAssertTrue(!visitorId.contains("-"))
    }

    func testNewPersistentData() {
        let uuid = UUID().uuidString
        let data = appDataModule?.newPersistentData(for: uuid)
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 1)
        XCTAssertEqual(mockDiskStorage.saveCount, 1)
        XCTAssertEqual(data?.dictionary.keys.sorted(), [TealiumKey.visitorId, TealiumKey.uuid].sorted())
    }

    func testSetNewAppData() {
        appDataModule?.storeNewAppData()
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 1)
        XCTAssertEqual(mockDiskStorage.saveCount, 1)
        XCTAssertNotNil(appDataModule?.appData.persistentData?.visitorId)
        XCTAssertNotNil(appDataModule?.appData.persistentData?.uuid)
    }

    func testSetLoadedAppData() {
        let config = TestTealiumHelper().getConfig()
        config.existingVisitorId = "someOtherVisitorId"
        let module = AppDataModule(config: config, delegate: self, diskStorage: mockDiskStorage, bundle: Bundle(for: type(of: self)))
        let testPersistentData = PersistentAppData(visitorId: "someVisitorId", uuid: "someUUID")
        module.loadPersistentAppData(data: testPersistentData)
        // 2x because of init in setUp
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 2)
        XCTAssertEqual(mockDiskStorage.saveCount, 2)
        guard let appData = appDataModule?.appData else {
            XCTFail("AppData should not be nil")
            return
        }
        XCTAssertNotNil(appData.name)
        XCTAssertNotNil(appData.rdns)
        XCTAssertNotNil(appData.build)
    }

    func testPersistentDataInitFromDictionary() {
        let data = [TealiumKey.visitorId: "someVisitorId", TealiumKey.uuid: "someUUID"]
        let persistentData = PersistentAppData.new(from: data)
        XCTAssertEqual(persistentData?.visitorId, "someVisitorId")
        XCTAssertEqual(persistentData?.uuid, "someUUID")
    }

    func testAppDataDictionary() {
        let appDataDict = appDataModule?.appData.dictionary
        XCTAssertNotNil(appDataDict?[TealiumKey.appName])
        XCTAssertNotNil(appDataDict?[TealiumKey.appRDNS])
        XCTAssertNotNil(appDataDict?[TealiumKey.visitorId])
        XCTAssertNotNil(appDataDict?[TealiumKey.uuid])
    }

}

extension AppDataModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

}
