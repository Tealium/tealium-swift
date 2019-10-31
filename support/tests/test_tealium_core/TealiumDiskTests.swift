//
//  TealiumDiskTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 18/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumDiskTests: XCTestCase {

    let helper = TestTealiumHelper()
    var config: TealiumConfig!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        config = helper.newConfig()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testInit() {
       let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
       XCTAssertNotNil(diskstorage)
       XCTAssertEqual(diskstorage.filePrefix, "\(TealiumTestValue.account).\(TealiumTestValue.profile)/")
       XCTAssertFalse(diskstorage.isCritical, "Default should be false")
       XCTAssertTrue(diskstorage.isDiskStorageEnabled)
    }

    // test that item saved to disk can be retrieved
    func testSave() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        diskstorage.save(TealiumTrackRequest(data: ["hello": "testing"], completion: nil), completion: nil)
        diskstorage.retrieve(as: TealiumTrackRequest.self) { _, data, _ in
            XCTAssertNotNil(data?.trackDictionary["hello"], "data unexpectedly missing")
            XCTAssertEqual(data?.trackDictionary["hello"] as! String, "testing", "unexpected data retrieved")
        }
    }

    func testAppend() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        diskstorage.save(TealiumTrackRequest(data: ["hello": "testing"], completion: nil), completion: nil)
        diskstorage.append(TealiumTrackRequest(data: ["newkey": "testing"], completion: nil)) { _, _, _ in
            diskstorage.retrieve(as: TealiumTrackRequest.self) { _, data, _ in
                XCTAssertNotNil(data?.trackDictionary["hello"], "data unexpectedly missing")
                XCTAssertEqual(data?.trackDictionary["hello"] as? String, "testing", "unexpected data retrieved")
                XCTAssertNotNil(data?.trackDictionary["newkey"], "data unexpectedly missing")
                XCTAssertEqual(data?.trackDictionary["newkey"] as! String, "testing", "unexpected data retrieved")
            }
        }
    }

}
