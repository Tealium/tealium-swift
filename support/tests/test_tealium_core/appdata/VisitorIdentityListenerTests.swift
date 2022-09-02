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
        dataLayer.deleteAll()
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    let dataLayer = DataLayer(config: TealiumConfig(account: "", profile: "", environment: ""))
    let identityKey = "id_key"
    let identityValue = "someIdentity"
    
    var identityListener: VisitorIdentityListener!

    func addIdentityValue(_ value: String) {
        dataLayer.add(data: [identityKey: value], expiry: .untilRestart)
    }

    func createIdentityListener() {
        identityListener = VisitorIdentityListener(dataLayer: dataLayer, visitorIdentityKey: identityKey)
    }

    func testDataAlreadyPresent() {
        addIdentityValue(self.identityValue)
        createIdentityListener()
        let expect = expectation(description: "onNewIdentity called")
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, self.identityValue)
            expect.fulfill()
        }
        waitForExpectations(timeout: 2)
    }

    func testDataNotAlreadyPresent() {
        let expect = expectation(description: "onNewIdentity called")
        createIdentityListener()
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, self.identityValue)
            expect.fulfill()
        }
        dataLayer.add(data: [identityKey: identityValue], expiry: .untilRestart)
        waitForExpectations(timeout: 2)
    }

    func testDataRemovedNotTrigger() {
        let expect = expectation(description: "onNewIdentity called only once")
        expect.assertForOverFulfill = true
        addIdentityValue(self.identityValue)
        createIdentityListener()
        let subscription = identityListener.onNewIdentity.subscribe { identity in
            XCTAssertEqual(identity, self.identityValue)
            expect.fulfill()
        }
        dataLayer.delete(for: identityKey)
        waitForExpectations(timeout: 2)
        TealiumQueues.backgroundSerialQueue.sync {
            subscription.dispose()
        }
    }

    func testDataChanged() {
        let expect = expectation(description: "onNewIdentity called")
        let expect2 = expectation(description: "onNewIdentity called for the second time")
        addIdentityValue(self.identityValue)
        createIdentityListener()
        identityListener.onNewIdentity.subscribeOnce { identity in
            XCTAssertEqual(identity, self.identityValue)
            expect.fulfill()
        }
        let identityValue2 = "someIdentity2"
        addIdentityValue(identityValue2)
        TealiumQueues.backgroundSerialQueue.sync {
            identityListener.onNewIdentity.subscribeOnce { identity in
                XCTAssertEqual(identity, identityValue2)
                expect2.fulfill()
            }
        }
        waitForExpectations(timeout: 2)
    }
}
