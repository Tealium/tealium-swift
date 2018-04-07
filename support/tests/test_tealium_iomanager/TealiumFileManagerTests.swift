//
//  TealiumIOManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/18/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

class TealiumFileManagerTests: XCTestCase {

    let uniqueId = "test.id"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSaveAndLoad() {
        let data: [String: AnyObject] = ["foo": "foo string value" as AnyObject,
                                          "bar": ["alpha", "beta", "gamma"] as AnyObject]

        _ = TealiumFileManager.save(data: data,
                                    forUniqueId: uniqueId)

        if let loaded = TealiumFileManager.loadData(forUniqueId: uniqueId) {
            XCTAssertTrue(loaded == data)
        } else {
            XCTFail("test failed")
        }
    }

    func testLoadCorruptedData() {
        _ = TealiumFileManager.deleteAllData(forUniqueId: uniqueId)

        let parentDir = "\(NSHomeDirectory())/.tealium/swift/"
        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("test failed")
        }
        let persistenceFilePath = "\(parentDir)/\(uniqueId).data"

        let data: Data = "S*D&(*#@J".data(using: String.Encoding.utf8)!

        FileManager.default.createFile(atPath: persistenceFilePath,
                                       contents: data,
                                       attributes: nil)

        let corruptData = TealiumFileManager.loadData(forUniqueId: uniqueId)

        XCTAssertTrue(corruptData == nil, "CorruptData not nil: \(String(describing: corruptData))")
    }

    func testDelete() {
        let data = ["foo": "foo string value" as AnyObject,
                    "bar": ["alpha", "beta", "gamma"] as AnyObject]
            as [String: AnyObject]
        let saveSuccessful = TealiumFileManager.save(data: data,
                                                     forUniqueId: uniqueId)
        XCTAssertTrue(saveSuccessful)
        let deleteSuccessful = TealiumFileManager.deleteAllData(forUniqueId: uniqueId)

        XCTAssertTrue(deleteSuccessful, "Delete data returned false.")
        XCTAssertTrue(TealiumFileManager.loadData(forUniqueId: uniqueId) == nil)
        XCTAssertFalse(TealiumFileManager.dataExists(forUniqueId: uniqueId))
    }

}
