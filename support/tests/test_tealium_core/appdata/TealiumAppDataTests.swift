//
//  AppDataModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

let mockDiskStorage = MockAppDataDiskStorage()
class AppDataModuleTests: XCTestCase {

    
    let appDataCollector = MockAppDataCollector()
    
    var module: AppDataModule? {
        let context = TestTealiumHelper.context(with: TestTealiumHelper().getConfig())
        return AppDataModule(context: context, delegate: self, diskStorage: mockDiskStorage, bundle: Bundle(for: type(of: self)), appDataCollector: appDataCollector)
    }
    
    func createModule(with dataLayer: DataLayerManagerProtocol? = nil, diskStorage: TealiumDiskStorageProtocol? = mockDiskStorage) -> AppDataModule {
        let context = TestTealiumHelper.context(with: TestTealiumHelper().getConfig(), dataLayer: dataLayer ?? DummyDataManager())
        return AppDataModule(context: context, delegate: self, diskStorage: diskStorage, bundle: Bundle(for: type(of: self)), appDataCollector: appDataCollector)
    }

    override func setUp() {
        mockDiskStorage.reset()
        let data = PersistentAppData(visitorId: TealiumTestValue.visitorID,
                                     uuid: TealiumTestValue.visitorID)
        mockDiskStorage.storedData = AnyCodable(data)
    }
    
    override func tearDownWithError() throws {
    }
    
    func testInitMigratesLegacyAppData() {
        let appDataModule = createModule(with: MockMigratedDataLayer(), diskStorage: nil)
        guard let data = appDataModule.data,
              let visId = data[TealiumDataKey.visitorId] as? String,
              let uuid = data[TealiumDataKey.uuid] as? String else {
            XCTFail("Nothing in persistent app data and there should be a visitor id and uuid.")
            return
        }
        XCTAssertEqual(visId, MockMigratedDataLayer.visitorId)
        XCTAssertEqual(uuid, MockMigratedDataLayer.uuid)
        let appData = appDataModule.diskStorage.retrieve(as: PersistentAppData.self)
        XCTAssertNotNil(appData)
        XCTAssertEqual(appData?.visitorId, MockMigratedDataLayer.visitorId)
        XCTAssertEqual(appData?.uuid, MockMigratedDataLayer.uuid)
    }
    
    func testInitRemovesAppDataFromDataLayerAfterMigration() {
        let migratedDataLayer = MockMigratedDataLayer()
        let _ = createModule(with: migratedDataLayer)
        XCTAssertEqual(mockDiskStorage.saveCount, 1)
        XCTAssertEqual(migratedDataLayer.deleteCount, 1)
    }
    
    func testInitCreatesNewVisitorWhenNoMigratedData() {
        let appDataModule = createModule(with: MockMigratedDataLayerNoData())
        guard let data = appDataModule.data,
              let visId = data[TealiumDataKey.visitorId] as? String,
              let uuid = data[TealiumDataKey.uuid] as? String else {
            XCTFail("Nothing in persistent app data and there should be a visitor id and uuid.")
            return
        }
        XCTAssertEqual(mockDiskStorage.saveCount, 0)
        XCTAssertEqual(visId, "someVisitorId")
        XCTAssertEqual(uuid, "someVisitorId")
    }

    func testInitSetsExistingAppData() {
        let module = createModule()
        XCTAssertEqual(mockDiskStorage.retrieveCount, 1)
        guard let data = module.data, let visId = data[TealiumDataKey.visitorId] as? String else {
            XCTFail("Nothing in persistent app data and there should be a test visitor id.")
            return
        }
        XCTAssertEqual(visId, "someVisitorId")
    }

    func testDeleteAllData() {
        module?.deleteAll()
        XCTAssertEqual(mockDiskStorage.deleteCount, 1)
    }

    func testIsMissingPersistentKeys() {
        let missingUUID = [TealiumDataKey.visitorId: "someVisitorId"]
        XCTAssertTrue(AppDataModule.isMissingPersistentKeys(data: missingUUID))
        let missingVisitorID = [TealiumDataKey.uuid: "someUUID"]
        XCTAssertTrue(AppDataModule.isMissingPersistentKeys(data: missingVisitorID))
        let neitherMissing = [TealiumDataKey.visitorId: "someVisitorId", TealiumDataKey.uuid: "someUUID"]
        XCTAssertFalse(AppDataModule.isMissingPersistentKeys(data: neitherMissing))
    }

    func testVisitorIdFromUUID() {
        let uuid = UUID().uuidString
        guard let visitorId = module?.visitorId(from: uuid) else {
            XCTFail("Visitor id should not be null")
            return
        }
        XCTAssertTrue(!visitorId.contains("-"))
    }

    func testNewPersistentData() {
        let uuid = UUID().uuidString
        let data = module?.newPersistentData(for: uuid)
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 1)
        XCTAssertEqual(mockDiskStorage.saveCount, 1)
        XCTAssertEqual(data?.dictionary.keys.sorted(), [TealiumDataKey.visitorId, TealiumDataKey.uuid].sorted())
    }

    func testSetNewAppData() {
        module?.storeNewAppData()
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 1)
        XCTAssertEqual(mockDiskStorage.saveCount, 1)
        XCTAssertNotNil(module?.appData.persistentData?.visitorId)
        XCTAssertNotNil(module?.appData.persistentData?.uuid)
    }

    func testNewVolatileData() {
        let module = createModule()
        module.newVolatileData()
        XCTAssertEqual(module.appData.name, "DummyAppName" )
        XCTAssertEqual(module.appData.rdns, "DummyRdns")
        XCTAssertEqual(module.appData.version, "DummyVersion")
        XCTAssertNotNil(module.appData.build, "DummyBuild")
    }

    func testSetLoadedAppData() {
        let config = TestTealiumHelper().getConfig()
        config.existingVisitorId = "someOtherVisitorId"
        let context = TestTealiumHelper.context(with: config)
        let module = AppDataModule(context: context, delegate: self, diskStorage: mockDiskStorage, bundle: Bundle(for: type(of: self)), appDataCollector: appDataCollector)
        let testPersistentData = PersistentAppData(visitorId: "someVisitorId", uuid: "someUUID")
        module.loadPersistentAppData(data: testPersistentData)
        // 2x because of init in setUp
        XCTAssertEqual(mockDiskStorage.saveToDefaultsCount, 2)
        XCTAssertEqual(mockDiskStorage.saveCount, 2)
        XCTAssertNotNil(module.appData.name)
        XCTAssertNotNil(module.appData.rdns)
        XCTAssertNotNil(module.appData.build)
    }

    func testPersistentDataInitFromDictionary() {
        let data = [TealiumDataKey.visitorId: "someVisitorId", TealiumDataKey.uuid: "someUUID"]
        let persistentData = PersistentAppData.new(from: data)
        XCTAssertEqual(persistentData?.visitorId, "someVisitorId")
        XCTAssertEqual(persistentData?.uuid, "someUUID")
    }

    func testAppDataDictionary() {
        let appDataDict = module?.appData.dictionary
        XCTAssertNotNil(appDataDict?[TealiumDataKey.appName])
        XCTAssertNotNil(appDataDict?[TealiumDataKey.appRDNS])
        XCTAssertNotNil(appDataDict?[TealiumDataKey.visitorId])
        XCTAssertNotNil(appDataDict?[TealiumDataKey.uuid])
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

class MockAppDataCollector: AppDataCollection {

    func name(bundle: Bundle) -> String? {
        "DummyAppName"
    }

    func rdns(bundle: Bundle) -> String? {
        "DummyRdns"
    }

    func version(bundle: Bundle) -> String? {
        "DummyVersion"
    }

    func build(bundle: Bundle) -> String? {
        "DummyBuild"
    }
}
