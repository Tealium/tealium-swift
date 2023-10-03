//
//  VisitorIdProviderTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 31/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class VisitorIdProviderTests: XCTestCase {

    let identityKey = "identity"
    let identityValue = "identityValue"
    let visitorId = "123456"
    lazy var hashedIdentityValue: String = {
        identityValue.sha256() ?? ""
    }()
    lazy var config: TealiumConfig = {
        let c = TealiumConfig(account: "", profile: "", environment: "")
        c.visitorIdentityKey = identityKey
        return c
    }()
    lazy var dataLayer: DataLayer = DataLayer(config: config)
    let onVisitorId = TealiumReplaySubject<String>()
    let diskStorage = mockDiskStorage
    var provider: VisitorIdProvider!
    
    override func setUpWithError() throws {
        diskStorage.delete(completion: nil)
        dataLayer.deleteAll()
        changeIdentityValue(to: identityValue)
    }
    func changeIdentityValue(to value: String) {
        dataLayer.add(key: identityKey, value: value, expiry: .untilRestart)
    }

    func createProvider(config: TealiumConfig? = nil, migrator: VisitorIdMigratorProtocol? = nil) {
        let config = config ?? self.config
        self.provider = nil
        diskStorage.save(VisitorIdStorage(visitorId: visitorId), completion: nil)
        let backup = TealiumBackupStorage(account: config.account,
                                          profile: config.profile)
        backup.clear()
        provider = VisitorIdProvider(config: config,
                                     dataLayer: self.dataLayer,
                                     diskStorage: diskStorage,
                                     visitorIdMigrator: migrator,
                                     backupStorage: backup)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMigrationFromDataLayer() {
        dataLayer.add(data: [
            TealiumDataKey.uuid: "oldUUID",
            TealiumDataKey.visitorId: "oldVisitorId"
        ], expiry: .untilRestart)
        createProvider()
        let data = dataLayer.all
        XCTAssertNil(data[TealiumDataKey.visitorId])
        XCTAssertEqual("oldUUID", data[TealiumDataKey.uuid] as? String)
        XCTAssertEqual(provider.visitorIdStorage.visitorId, "oldVisitorId")
    }

    func testMigrationFromPersistentAppData() {
        let oldDiskStorage = MockAppDataDiskStorage()
        oldDiskStorage.save(PersistentAppData(visitorId: "oldVisitorId", uuid: "oldUUID"), completion: nil)
        XCTAssertNotNil(oldDiskStorage.storedData)
        let migrator = VisitorIdMigrator(dataLayer: MockDataLayerManager(),
                                         config: self.config,
                                         diskStorage: oldDiskStorage,
                                         backupStorage: TealiumBackupStorage(account: config.account,
                                                                             profile: config.profile))
        createProvider(config: nil, migrator: migrator)
        let data = dataLayer.all
        XCTAssertNil(data[TealiumDataKey.visitorId])
        XCTAssertNil(oldDiskStorage.storedData)
        XCTAssertEqual("oldUUID", data[TealiumDataKey.uuid] as? String)
        XCTAssertEqual(provider.visitorIdStorage.visitorId, "oldVisitorId")
    }

    func testVisitorIdFromNewDiskStorage() {
        createProvider()
        XCTAssertEqual(provider.visitorIdStorage.visitorId, visitorId)
        let data = dataLayer.all
        XCTAssertNil(data[TealiumDataKey.visitorId])
        XCTAssertNotNil(data[TealiumDataKey.uuid])
    }
    
    func testKeysAreHashed() {
        createProvider()
        XCTAssertEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId)
        let keys = provider.visitorIdStorage.cachedIds.keys
        XCTAssertFalse(keys.contains { $0 == identityValue })
        XCTAssertTrue(keys.contains { $0 == hashedIdentityValue })
    }

    func testCurrentIdentityIsHashed() {
        createProvider()
        XCTAssertEqual(provider.visitorIdStorage.currentIdentity, hashedIdentityValue)
    }

    func testResetVisitorId() {
        createProvider()
        XCTAssertEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId)
        let resultId = provider.resetVisitorId()
        XCTAssertNotEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId)
        XCTAssertEqual(resultId, provider.getVisitorId(forKey: hashedIdentityValue))
    }

    func testChangeIdentityKey() {
        createProvider()
        let expect = expectation(description: "VisitorId has changed")
        let sub = provider.onVisitorId.subscribe { id in
            if id != self.visitorId {
                expect.fulfill()
            }
        }
        changeIdentityValue(to: "someOtherValue")
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId, "Old visitorId for old identifier hasn't changed")
        }
        waitForExpectations(timeout: 3)
        TealiumQueues.backgroundSerialQueue.sync {
            sub.dispose()
        }
    }

    func testChangeIdentityKeyAndBack() {
        createProvider()
        let visitorChanged = expectation(description: "VisitorId has changed")
        var count = 0
        let visitorBackToFirst = expectation(description: "VisitorId is back to first")
        let sub = provider.onVisitorId.subscribe { id in
            count += 1
            if id != self.visitorId {
                visitorChanged.fulfill()
            }
            if count == 3 && id == self.visitorId {
                visitorBackToFirst.fulfill()
            }
        }
        changeIdentityValue(to: "someOtherValue")
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId, "Old visitorId for old identifier hasn't changed")
        }
        changeIdentityValue(to: identityValue)
        TealiumQueues.backgroundSerialQueue.sync {
            let cachedIdentities = provider.visitorIdStorage.cachedIds.keys
            XCTAssertEqual(cachedIdentities.count, 2)
            XCTAssertTrue(cachedIdentities.contains { $0 == hashedIdentityValue })
            XCTAssertTrue(cachedIdentities.contains { $0 == "someOtherValue".sha256() })
        }
        waitForExpectations(timeout: 10)
        TealiumQueues.backgroundSerialQueue.sync {
            sub.dispose()
        }
    }

    func testNothingHappensWithoutIdentityKey() {
        let config = self.config.copy
        config.visitorIdentityKey = nil
        
        createProvider(config: config)
        let expect = expectation(description: "Visitor Id doesn't change")
        expect.assertForOverFulfill = true
        let sub = provider.onVisitorId.subscribe { id in
            XCTAssertEqual(id, self.visitorId)
            expect.fulfill()
        }
        changeIdentityValue(to: "someOtherValue")
        waitForExpectations(timeout: 5)
        TealiumQueues.backgroundSerialQueue.sync {
            sub.dispose()
        }
    }

    func testDeleteDataLayerNotTriggerNewVisitorIds() {
        createProvider()
        let expect = expectation(description: "Visitor Id doesn't change")
        expect.assertForOverFulfill = true
        let sub = provider.onVisitorId.subscribe { id in
            expect.fulfill()
            XCTAssertEqual(self.visitorId, id)
        }
        createProvider()
        waitForExpectations(timeout: 3)
        TealiumQueues.backgroundSerialQueue.sync {
            sub.dispose()
        }
    }

    func testClearStoredVisitorIds() {
        createProvider()
        XCTAssertGreaterThan(provider.visitorIdStorage.cachedIds.count, 0)
        XCTAssertEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId)
        provider.clearStoredVisitorIds()
        XCTAssertNotNil(provider.getVisitorId(forKey: hashedIdentityValue))
        XCTAssertNotEqual(provider.getVisitorId(forKey: hashedIdentityValue), visitorId, "VisitorId for the same identity has to change")
        XCTAssertNotNil(provider.visitorIdStorage.currentIdentity, "Identity doesn't get cleared if the identity is still in the dataLayer")
        XCTAssertEqual(provider.visitorIdStorage.cachedIds.count, 1)
        dataLayer.delete(for: self.identityKey)
        provider.clearStoredVisitorIds()
        XCTAssertNil(provider.getVisitorId(forKey: hashedIdentityValue))
        XCTAssertNil(provider.getVisitorId(forKey: hashedIdentityValue))
        XCTAssertNil(provider.visitorIdStorage.currentIdentity, "Identity does get cleared if the identity is cleared from dataLayer")
        XCTAssertEqual(provider.visitorIdStorage.cachedIds.count, 0)
    }

    func testPublishVisitorId() {
        let expectation = expectation(description: "New id is published")
        createProvider()
        provider.publishVisitorId("newId", andUpdateStorage: false)
        provider.onVisitorId.subscribe { id in
            if id == "newId" {
                expectation.fulfill()
            }
        }
        XCTAssertNotEqual(provider.visitorIdStorage.visitorId, "newId")
        let idStorage = diskStorage.retrieve(as: VisitorIdStorage.self)
        XCTAssertNotNil(idStorage)
        XCTAssertNotEqual(idStorage?.visitorId, "newId")
        waitForExpectations(timeout: 2.0)
    }

    func testPublishVisitorIdAndUpdate() {
        let expectation = expectation(description: "New id is published")
        createProvider()
        provider.publishVisitorId("newId", andUpdateStorage: true)
        provider.onVisitorId.subscribe { id in
            if id == "newId" {
                expectation.fulfill()
            }
        }
        XCTAssertEqual(provider.visitorIdStorage.visitorId, "newId")
        let idStorage = diskStorage.retrieve(as: VisitorIdStorage.self)
        XCTAssertNotNil(idStorage)
        XCTAssertEqual(idStorage?.visitorId, "newId")
        waitForExpectations(timeout: 2.0)
    }
}
