//
//  TealiumAppDataTests.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/19/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import TealiumAppData
@testable import TealiumCore
import XCTest

class TealiumAppDataTests: XCTestCase {

    var appData: TealiumAppData?
    var bundle: Bundle?

    override func setUp() {
        super.setUp()
        appData = TealiumAppData(diskStorage: MockDiskStorage())
        bundle = Bundle(for: TealiumAppData.self)
    }

    override func tearDown() {
        appData = nil
        super.tearDown()
    }

    func testSetExistingAppDataLegacyData() {
        appData = TealiumAppData(diskStorage: MockDiskStorage(), legacyMigrator: MockTealiumMigratorWithData.self)
        appData?.setExistingAppData()
        XCTAssertEqual("legacyVID", appData?.appData.persistentData?.visitorId, "Visitor ID Mismatch")
        XCTAssertEqual("legacyUUID", appData?.appData.persistentData?.uuid, "UUID Mismatch")
    }

    func testSetExistingAppDataNewData() {
        appData = TealiumAppData(diskStorage: MockDiskStorage(), legacyMigrator: MockTealiumMigratorNoData.self)
        appData?.setExistingAppData()
        XCTAssertEqual(TealiumTestValue.visitorID, appData?.appData.persistentData?.visitorId, "Visitor ID Mismatch")
        XCTAssertEqual(TealiumTestValue.visitorID, appData?.appData.persistentData?.uuid, "UUID Mismatch")
    }

    func testDeleteAllData() {
        appData?.setLoadedAppData(data: PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID))
        XCTAssertEqual(6, appData?.count, "tealiumAppData counts do not match")
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
        guard let newData = appData?.newPersistentData(for: testUuid).toDictionary() else {

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

        appData.newVolatileData()

       let appDataVolatile = appData.appData
        XCTAssertNotNil(appDataVolatile.name)
        XCTAssertNotNil(appDataVolatile.rdns)
        XCTAssertNotNil(appDataVolatile.version)
        XCTAssertNotNil(appDataVolatile.build)
    }

    func testSetNewAppDataAddsPersistentData() {
        guard let appData = appData else {
            XCTFail("appData not initialized correctly")
            return
        }
        appData.setNewAppData()
        let result = appData.getData()

        XCTAssertNotNil(result[TealiumKey.uuid] as? String)
        XCTAssertNotNil(result[TealiumKey.visitorId] as? String)
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
        XCTAssertNotEqual(result1[TealiumKey.uuid] as? String, result2[TealiumKey.uuid] as? String)
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

    func testSetLoadedAppDataAddsNewVolatileData() {
        guard let appData = appData else {
            XCTFail("TealiumAppData not initialized correctly")
            return
        }
        XCTAssertEqual(6, appData.count)
        appData.setLoadedAppData(data: PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID))
            let result = appData.getData()
        XCTAssertNotNil(result[TealiumAppDataKey.name] as? String)

        XCTAssertEqual(TealiumTestValue.visitorID, result[TealiumKey.visitorId] as? String)

        XCTAssertEqual(TealiumTestValue.visitorID, result[TealiumKey.uuid] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.rdns] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.version] as? String)
        XCTAssertNotNil(result[TealiumAppDataKey.build] as? String)
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

class MockDiskStorage: TealiumDiskStorageProtocol {

    func append(_ data: [String: Any], fileName: String, completion: TealiumCompletion?) {

    }

    func update<T>(value: Any, for key: String, as type: T.Type, completion: TealiumCompletion?) where T: Decodable, T: Encodable {

    }

    func save(_ data: AnyCodable, completion: TealiumCompletion?) {

    }

    func save(_ data: AnyCodable, fileName: String, completion: TealiumCompletion?) {
    }

    func save<T>(_ data: T, completion: TealiumCompletion?) where T: Encodable {
    }

    func save<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Encodable {
    }

    func append<T>(_ data: T, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func append<T>(_ data: T, fileName: String, completion: TealiumCompletion?) where T: Decodable, T: Encodable {
    }

    func retrieve<T>(as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
        guard T.self == PersistentAppData.self,
            let completion = completion as? (Bool, PersistentAppData?, Error?) -> Void
        else {
            return
        }
        completion(true, PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID), nil)
    }

    func retrieve<T>(_ fileName: String, as type: T.Type, completion: @escaping (Bool, T?, Error?) -> Void) where T: Decodable {
    }

    func retrieve<T>(as type: T.Type) -> T? where T: Decodable {
        guard T.self == PersistentAppData.self else {
            return nil
        }
        return PersistentAppData(visitorId: TealiumTestValue.visitorID, uuid: TealiumTestValue.visitorID) as? T
    }

    func retrieve<T>(_ fileName: String, as type: T.Type) -> T? where T: Decodable {
        return nil
    }

    func retrieve(fileName: String, completion: (Bool, [String: Any]?, Error?) -> Void) {

    }

    func append(_ data: [String: Any], forKey: String, fileName: String, completion: TealiumCompletion?) {

    }

    func delete(completion: TealiumCompletion?) {
        completion?(true, nil, nil)
    }

    func totalSizeSavedData() -> String? {
        return "1000"
    }

    func saveStringToDefaults(key: String, value: String) {

    }

    func getStringFromDefaults(key: String) -> String? {
        return ""
    }

    func saveToDefaults(key: String, value: Any) {

    }

    func getFromDefaults(key: String) -> Any? {
        return ""
    }

    func removeFromDefaults(key: String) {

    }

    func canWrite() -> Bool {
        return true
    }
}

class MockTealiumMigratorWithData: TealiumLegacyMigratorProtocol {
    static func getLegacyData(forModule module: String) -> [String: Any]? {
        return [
            TealiumKey.visitorId: "legacyVID",
            TealiumKey.uuid: "legacyUUID"
        ]
    }

    static func getLegacyDataArray(forModule module: String) -> [[String: Any]]? {
        return nil
    }

}

class MockTealiumMigratorNoData: TealiumLegacyMigratorProtocol {
    static func getLegacyData(forModule module: String) -> [String: Any]? {
        return nil
    }

    static func getLegacyDataArray(forModule module: String) -> [[String: Any]]? {
        return nil
    }

}
