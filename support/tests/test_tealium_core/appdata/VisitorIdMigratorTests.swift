//
//  VisitorIdMigratorTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 03/10/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

private let dataLayer = DataLayer(config: TestTealiumHelper().getConfig())
class VisitorIdMigratorTests: XCTestCase {

    let migrator = VisitorIdMigrator(dataLayer: dataLayer,
                                     config: dataLayer.config, diskStorage: mockDiskStorage)
    
    override func setUpWithError() throws {
    }

    func testGetOldPersistentDataFromDataLayer() throws {
        dataLayer.add(data: [
            TealiumDataKey.uuid: "1",
            TealiumDataKey.visitorId: "2"
        ], expiry: Expiry.untilRestart)
        
        let persistentData = migrator.getOldPersistentData()
        XCTAssertNotNil(persistentData)
        XCTAssertEqual(persistentData?.uuid, "1")
        XCTAssertEqual(persistentData?.visitorId, "2")
        migrator.deleteOldPersistentData()
        let data = dataLayer.all
        XCTAssertNil(data[TealiumDataKey.visitorId])
        XCTAssertNotNil(data[TealiumDataKey.uuid])
    }

    func testGetOldPersistentDataFromDiskStorage() {
        mockDiskStorage.save(PersistentAppData(visitorId: "testVisitor", uuid: "testUUID"), completion: nil)
        let persistentData = migrator.getOldPersistentData()
        XCTAssertNotNil(persistentData)
        XCTAssertEqual(persistentData?.uuid, "testUUID")
        XCTAssertEqual(persistentData?.visitorId, "testVisitor")
        migrator.deleteOldPersistentData()
        XCTAssertNil(migrator.getOldPersistentData())
        XCTAssertNotNil(dataLayer.all[TealiumDataKey.uuid])
    }

    func testGetOldPersistentDataNoMigrationNeeded() {
        let persistentData = migrator.getOldPersistentData()
        XCTAssertNil(persistentData)
    }
}
