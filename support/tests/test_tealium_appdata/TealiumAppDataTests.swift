//
//  TealiumAppDataTests.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/19/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumAppDataTests: XCTestCase {

    var appData: TealiumAppData?
    var appDataModule: TealiumAppDataModule?
    var saveDelegateCalled = 0

    override func setUp() {
        super.setUp()

        let helper = TestTealiumHelper()
        let enableRequest = TealiumEnableRequest(config: helper.getConfig(), enableCompletion: nil)
        let module = TealiumAppDataModule(delegate: self)
        module.enable(enableRequest)

        appDataModule = module
        appData = module.appData as? TealiumAppData
        appData?.delegate = self
    }

    override func tearDown() {
        appData = nil
        super.tearDown()
    }

    func testDeleteAllData() {
        appData?.add(data: ["a": "1", "b": "2"])
        XCTAssertEqual(2, appData?.count, "tealiumAppData counts do not match")
        appData?.deleteAllData()
        XCTAssertEqual(0, appData?.count, "tealiumAppData did not deleteAllData")
    }

    func testIsMissingPersistentKeys() {
        let emptyDict = [String: Any]()
        let failingDict = ["blah": "hah"]
        let numericDict = ["23": 56]
        let passingDict = ["app_uuid": "abc123",
                           "tealium_visitor_id": "abc123"]

        XCTAssertTrue(TealiumAppData.isMissingPersistentKeys(data: emptyDict))
        XCTAssertTrue(TealiumAppData.isMissingPersistentKeys(data: failingDict))
        XCTAssertTrue(TealiumAppData.isMissingPersistentKeys(data: numericDict))
        XCTAssertFalse(TealiumAppData.isMissingPersistentKeys(data: passingDict))
    }

    func testNewPersistentData() {
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let manualVid = "123e4567e89b12d3a456426655440000"
        let vid = appData?.visitorId(from: testUuid)

        XCTAssertTrue(manualVid == vid, "VisitorId method does not modify string correctly. \n Returned:\(String(describing: vid)) \n Expected:\(manualVid)")
        guard let newData = appData?.newPersistentData(for: testUuid) else {

            XCTFail("Could not create newPersistent data from appDataModule")
            return
        }

        let checkData = [
            "app_uuid": testUuid as AnyObject,
            "tealium_visitor_id": manualVid as AnyObject,
        ]

        XCTAssertTrue(checkData == newData, "Mismatch between newPersistentData:\n\(newData) \nAnd manualCheckData:\n\(checkData)")
    }

    func testVisitorId() {
        let testUuid = "123e4567-e89b-12d3-a456-426655440000"
        let vid = appData?.visitorId(from: testUuid)

        let vidCheck = "123e4567e89b12d3a456426655440000"

        XCTAssertTrue(vidCheck == vid, "Visitor id mismatch between returned vid:\(String(describing: vid)) \nAnd manual check:\(vidCheck)")
    }

    func testForMissingKeys() {
        guard let appData = appData else {
            XCTFail("TealiumAppData not initialized correctly")
            return
        }
        appData.setNewAppData()
        let expectedKeys = ["app_build",
                            "app_name",
                            "app_rdns",
                            "app_version",
                            "app_uuid",
                            "tealium_visitor_id",
        ]

        let result = appData.getData()
        for key in expectedKeys where result[key] == nil {
            XCTFail("Missing key: \(key). AppData: \(appData)")
        }
    }

    func testNewVolatileDataHasCorrectKeys() {
        guard let appData = appData else {
            XCTFail("appData not initailized correctly")
            return
        }
        let result = appData.newVolatileData()

        XCTAssertNotNil(result[TealiumAppDataKey.name] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.rdns] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.version] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.build] as? String)
    }

    func testSetNewAppDataAddsPersistentData() {
        guard let appData = appData else {
            XCTFail("appData not initialized correctly")
            return
        }
        appData.setNewAppData()
        let result = appData.getData()

        XCTAssertNotNil(result[TealiumAppDataKey.uuid] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.visitorId] as? String)
    }

    func testSetNewAppDataHasUniqueUuids() {
        guard let appData = appData else {
            XCTFail("appData not initialized correctly")
            return
        }
        appData.setNewAppData()
        let result1 = appData.getData()

        appData.setNewAppData()
        let result2 = appData.getData()
        XCTAssertNotEqual(result1[TealiumAppDataKey.uuid] as? String, result2[TealiumAppDataKey.uuid] as? String)
    }

    func testSetNewAppDataAddsVolatileData() {
        guard let appData = appData else {
            XCTFail("TealiumAppData not initialized correctly")
            return
        }
        appData.setNewAppData()
        let result = appData.getData()

        XCTAssertNotNil(result[TealiumAppDataKey.name] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.rdns] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.version] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.build] as? String)
    }

    func testSetNewAppDataCallsSave() {
        guard let appData = appData else {
            XCTFail("TealiumAppData not initialized correctly")
            return
        }
        XCTAssertEqual(0, saveDelegateCalled)
        appData.setNewAppData()
        XCTAssertEqual(1, saveDelegateCalled)
    }

    func testSetLoadedAppDataAddsNewVolatileData() {
        guard let appData = appData else {
            XCTFail("TealiumAppData not initialized correctly")
            return
        }
        XCTAssertEqual(0, appData.count)
        appData.setLoadedAppData(data: ["a": "1"])
        let result = appData.getData()

        XCTAssertNotNil(result[TealiumAppDataKey.name] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.rdns] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.version] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.build] as? String)
        XCTAssertNotNil(result["a"] as? String)
    }
}

extension TealiumAppDataTests: TealiumModuleDelegate {
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if process is TealiumEnableRequest {
            return
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
    }
}

extension TealiumAppDataTests: TealiumSaveDelegate {
    func savePersistentData(data: [String: Any]) {
        saveDelegateCalled += 1
    }
}
