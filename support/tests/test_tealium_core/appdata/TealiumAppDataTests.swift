//
//  AppDataModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

let mockDiskStorage = MockAppDataDiskStorage()
private let datamanager = DummyDataManager()
class AppDataModuleTests: XCTestCase {

    let appDataCollector = MockAppDataCollector()
    
    var module: AppDataModule? {
        createModule()
    }
    
    func createModule(with dataLayer: DataLayerManagerProtocol? = nil, diskStorage: TealiumDiskStorageProtocol? = mockDiskStorage) -> AppDataModule {
        let context = TestTealiumHelper.context(with: TestTealiumHelper().getConfig(), dataLayer: dataLayer ?? datamanager)
        return AppDataModule(context: context, delegate: self, diskStorage: diskStorage, bundle: Bundle(for: type(of: self)), appDataCollector: appDataCollector)
    }

    override func setUp() {
        mockDiskStorage.reset()
        let data = VisitorIdStorage(visitorId: TealiumTestValue.visitorID)
        mockDiskStorage.save(data, completion: nil)
    }
    
    override func tearDownWithError() throws {
    }

    func testInitSetsExistingAppData() {
        let module = createModule()
        XCTAssertEqual(mockDiskStorage.retrieveCount, 1)
        guard let data = module.data, let visId = data[TealiumDataKey.visitorId] as? String else {
            XCTFail("Nothing in persistent app data and there should be a test visitor id.")
            return
        }
        XCTAssertEqual(visId, TealiumTestValue.visitorID)
    }

    func testVisitorIdFromUUID() {
        let uuid = UUID().uuidString
        let visitorId = VisitorIdProvider.visitorId(from: uuid)
        XCTAssertTrue(!visitorId.contains("-"))
    }

    func testNewVolatileData() {
        let module = createModule()
        module.newVolatileData()
        XCTAssertEqual(module.appData.name, "DummyAppName" )
        XCTAssertEqual(module.appData.rdns, "DummyRdns")
        XCTAssertEqual(module.appData.version, "DummyVersion")
        XCTAssertNotNil(module.appData.build, "DummyBuild")
    }

    func testAppDataDictionary() {
        let module = createModule()
        let appDataDict = module.data
        XCTAssertNotNil(appDataDict?[TealiumDataKey.appName])
        XCTAssertNotNil(appDataDict?[TealiumDataKey.appRDNS])
        XCTAssertNotNil(appDataDict?[TealiumDataKey.visitorId])
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
