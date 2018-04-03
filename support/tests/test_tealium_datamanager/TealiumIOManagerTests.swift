//
//  TealiumIOManagerTests.swift
//  tealium-swift
//
//  Created by Chad Hartman on 9/2/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

class TealiumIOManagerTests: XCTestCase {

    let account  = "tealiummobile"
    let profile  = "demo"
    let env  = "dev"
    var ioManager: TealiumIOManager?

    override func setUp() {
        super.setUp()

        guard let iom = createTestInstance() else {
            XCTFail("Could not startup the ioManager.")
            return
        }

        ioManager = iom
    }

    override func tearDown() {
        _ = ioManager?.deleteData()
        super.tearDown()
    }

    func testLoadEmptyDefaults() {
        guard let ioManager = self.ioManager else {
            XCTFail("ioManager not available to run test.")
            return
        }

        let defaults = ioManager.loadDefaultsData()

        XCTAssertTrue(defaults == nil)
    }

    func testSaveAndLoad() {
        guard let ioManager = self.ioManager else {
            XCTFail("ioManager not available to run test.")
            return
        }

        let data: [String: AnyObject] = ["foo": "foo string value" as AnyObject,
                                          "bar": ["alpha", "beta", "gamma"] as AnyObject]

        ioManager.saveData(data as [String: AnyObject])

        if let loaded = ioManager.loadData() {
            XCTAssertTrue(loaded == data)
        } else {
            XCTFail("test failed")
        }
    }

    func testLoadCorruptedData() {
        guard let ioManager = self.ioManager else {
            XCTFail("ioManager not available to run test.")
            return
        }

        let parentDir = "\(NSHomeDirectory())/.tealium/swift/"
        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("test failed")
        }
        let persistenceFilePath = "\(parentDir)/\(account)_\(profile)_\(env).data"

        let data: Data = "S*D&(*#@J".data(using: String.Encoding.utf8)!

        FileManager.default.createFile(atPath: persistenceFilePath,
                                       contents: data,
                                       attributes: nil)

        XCTAssertTrue(ioManager.loadData() == nil)
    }

    func testDelete() {
        guard let ioManager = self.ioManager else {
            XCTFail("ioManager not available to run test.")
            return
        }

        let data = ["foo": "foo string value", "bar": ["alpha", "beta", "gamma"]] as [String: Any]
        ioManager.saveData(data as [String: AnyObject])
        _ = ioManager.deleteData()
        XCTAssertTrue(ioManager.loadData() == nil)
        XCTAssertTrue(!ioManager.persistedDataExists())
    }

    fileprivate func createTestInstance() -> TealiumIOManager? {
        do {
            let t = try TealiumIOManager(account: account, profile: profile, env: env)
            return t
        } catch _ {
            return nil
        }
    }

}
