//
//  VisitorIdStorageTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 03/10/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class VisitorIdStorageTests: XCTestCase {

    func testSetCurrentVisitorIdForCurrentIdentity() throws {
        var storage = VisitorIdStorage(visitorId: "id")
        storage.currentIdentity = "identity"
        XCTAssertNil(storage.cachedIds["identity"])
        storage.setCurrentVisitorIdForCurrentIdentity()
        XCTAssertEqual("id", storage.cachedIds["identity"])
    }

    func testSetVisitorIdForCurrentIdentity() throws {
        var storage = VisitorIdStorage(visitorId: "id")
        storage.currentIdentity = "identity"
        XCTAssertNil(storage.cachedIds["identity"])
        storage.setVisitorIdForCurrentIdentity("id2")
        XCTAssertEqual("id2", storage.cachedIds["identity"])
    }
}
