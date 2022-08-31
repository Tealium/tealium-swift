//
//  VisitorIdentityListenerTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 31/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class VisitorIdentityListenerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDataAlreadyPresent() {
        let expect = expectation(description: "onNewIdentity called")
        let dataLayer = DataLayer(config: TealiumConfig(account: "", profile: "", environment: ""))
        let identityKey = "id_key"
        let identityValue = "someIdentity"
        dataLayer.add(data: [identityKey: identityValue])
        let identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, identityValue)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testDataNotAlreadyPresent() {
        let expect = expectation(description: "onNewIdentity called")
        let dataLayer = DataLayer(config: TealiumConfig(account: "", profile: "", environment: ""))
        let identityKey = "id_key"
        let identityValue = "someIdentity"
        let identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, identityValue)
            expect.fulfill()
        }
        dataLayer.add(data: [identityKey: identityValue])
        waitForExpectations(timeout: 2)
    }

    func testDataRemovedNotTrigger() {
        let expect = expectation(description: "onNewIdentity called only once")
        expect.assertForOverFulfill = true
        let dataLayer = DataLayer(config: TealiumConfig(account: "", profile: "", environment: ""))
        let identityKey = "id_key"
        let identityValue = "someIdentity"
        dataLayer.add(data: [identityKey: identityValue])
        let identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        let subscription = identityListener.onNewIdentity.subscribe { identity in
            XCTAssertEqual(identity, identityValue)
            expect.fulfill()
        }
        dataLayer.delete(for: identityKey)
        waitForExpectations(timeout: 2)
        subscription.dispose()
    }

    func testDataChanged() {
        let expect = expectation(description: "onNewIdentity called")
        let expect2 = expectation(description: "onNewIdentity called for the second time")
        let dataLayer = DataLayer(config: TealiumConfig(account: "", profile: "", environment: ""))
        let identityKey = "id_key"
        let identityValue = "someIdentity"
        dataLayer.add(data: [identityKey: identityValue])
        let identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, identityValue)
            expect.fulfill()
        }
        let identityValue2 = "someIdentity2"
        dataLayer.add(data: [identityKey: identityValue2])
        TealiumQueues.backgroundSerialQueue.sync {
            identityListener.onNewIdentity.subscribeOnce { identity in
                XCTAssertEqual(identity, identityValue2)
                expect2.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
}
