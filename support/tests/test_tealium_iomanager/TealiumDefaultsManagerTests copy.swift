//
//  TealiumIOManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

class TealiumDefaultsManagerTests: XCTestCase {

    let uniqueId = "test.id"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        _ = TealiumDefaultsManager.deleteAllData(forUniqueId: uniqueId)
        super.tearDown()
    }

    func testSaveAndLoad() {
        let data: [String: AnyObject] = ["foo": "foo string value" as AnyObject,
                                          "bar": ["alpha", "beta", "gamma"] as AnyObject]

        _ = TealiumDefaultsManager.save(data: data,
                                        forUniqueId: uniqueId)

        if let loaded = TealiumDefaultsManager.loadData(forUniqueId: uniqueId) {
            XCTAssertTrue(loaded == data)
        } else {
            XCTFail("test failed")
        }
    }

    func testDelete() {
        let data = ["foo": "foo string value" as AnyObject,
                    "bar": ["alpha", "beta", "gamma"] as AnyObject]
            as [String: AnyObject]
        let saveSuccessful = TealiumDefaultsManager.save(data: data,
                                                         forUniqueId: uniqueId)
        XCTAssertTrue(saveSuccessful)
        let deleteSuccessful = TealiumDefaultsManager.deleteAllData(forUniqueId: uniqueId)

        XCTAssertTrue(deleteSuccessful, "Delete data returned false.")
        XCTAssertTrue(TealiumDefaultsManager.loadData(forUniqueId: uniqueId) == nil)
        XCTAssertFalse(TealiumDefaultsManager.dataExists(forUniqueId: uniqueId))
    }

}
