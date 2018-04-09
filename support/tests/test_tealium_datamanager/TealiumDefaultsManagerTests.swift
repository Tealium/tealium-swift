//
//  TealiumDefaultsManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/3/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

class TealiumDefaultsManagerTests: XCTestCase {

    var defaultsManager: TealiumDefaultsManager?

    override func setUp() {
        super.setUp()

        do {
            let dm = try TealiumDefaultsManager(account: "a", profile: "b", env: "c")
            self.defaultsManager = dm
        } catch {
            XCTFail("DefaultsManager could not initialized.")
        }

    }

    override func tearDown() {
        _ = defaultsManager?.deleteData()
        super.tearDown()
    }

    func testAll() {
        guard let defaultsManager = self.defaultsManager else {
            XCTFail("Defaults manager not available to test.")
            return
        }

        let testData = ["key": "value" as AnyObject] as [String: AnyObject]

        // Save
        defaultsManager.saveData(data: testData)

        // Load
        guard let savedData = defaultsManager.loadData() else {
            XCTFail("Could not retrieve saved data.")
            return
        }

        XCTAssertTrue(testData == savedData, "Data mismatch between testData: \(testData) and loadedSavedData: \(savedData)")

        // Persisted data file
        XCTAssertTrue(defaultsManager.persistedDataExists())

        let didDelete = defaultsManager.deleteData()

        XCTAssertTrue(didDelete)
        XCTAssertTrue(defaultsManager.loadData() == nil)
    }
}
