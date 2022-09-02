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
    
    func createProvider(config: TealiumConfig? = nil) {
        self.provider = nil
        onVisitorId.publish(visitorId)
        provider = VisitorIdProvider(config: config ?? self.config, dataLayer: self.dataLayer, onVisitorId: onVisitorId, diskStorage: diskStorage)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testKeysAreHashed() {
        createProvider()
        XCTAssertEqual(provider.getVisitorId(forKey: identityValue), visitorId)
        let keys = provider.visitorIdMap.cachedIds.keys
        XCTAssertFalse(keys.contains { $0 == identityValue })
        XCTAssertTrue(keys.contains { $0 == identityValue.sha256() })
    }

    func testResetVisitorId() {
        createProvider()
        XCTAssertEqual(provider.getVisitorId(forKey: identityValue), visitorId)
        let resultId = provider.resetVisitorId()
        XCTAssertNotEqual(provider.getVisitorId(forKey: identityValue), visitorId)
        XCTAssertEqual(resultId, provider.getVisitorId(forKey: identityValue))
    }

    func testChangeIdentityKey() {
        createProvider()
        let expect = expectation(description: "VisitorId has changed")
        let sub = onVisitorId.subscribe { id in
            if id != self.visitorId {
                expect.fulfill()
            }
        }
        changeIdentityValue(to: "someOtherValue")
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(provider.getVisitorId(forKey: identityValue), visitorId, "Old visitorId for old identifier hasn't changed")
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
        let sub = onVisitorId.subscribe { id in
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
            XCTAssertEqual(provider.getVisitorId(forKey: identityValue), visitorId, "Old visitorId for old identifier hasn't changed")
        }
        changeIdentityValue(to: identityValue)
        TealiumQueues.backgroundSerialQueue.sync {
            let cachedIdentities = provider.visitorIdMap.cachedIds.keys
            XCTAssertEqual(cachedIdentities.count, 2)
            XCTAssertTrue(cachedIdentities.contains { $0 == identityValue.sha256() })
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
        let sub = onVisitorId.subscribe { id in
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
        let expect = expectation(description: "Visitor Id doesn't change")
        expect.assertForOverFulfill = true
        let sub = onVisitorId.subscribe { id in
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
        XCTAssertGreaterThan(provider.visitorIdMap.cachedIds.count, 0)
        XCTAssertEqual(provider.getVisitorId(forKey: identityValue), visitorId)
        provider.clearStoredVisitorIds()
        XCTAssertNotEqual(provider.getVisitorId(forKey: identityValue), visitorId)
        XCTAssertNotNil(provider.visitorIdMap.currentIdentity, "Identity doesn't get cleared")
        XCTAssertEqual(provider.visitorIdMap.cachedIds.count, 1)
    }
}
