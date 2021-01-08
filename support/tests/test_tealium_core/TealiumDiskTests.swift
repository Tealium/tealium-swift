//
//  TealiumDiskTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumDiskTests: XCTestCase {

    let helper = TestTealiumHelper()
    var config: TealiumConfig!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        config = TealiumConfig(account: "account", profile: "profile", environment: "env")
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
        XCTAssertEqual(diskstorage.filePrefix, "account.profile/")
        XCTAssertFalse(diskstorage.isCritical, "Default should be false")
        XCTAssertTrue(diskstorage.isDiskStorageEnabled)
    }

    // test that item saved to disk can be retrieved
    func testSave() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        diskstorage.save(TealiumTrackRequest(data: ["hello": "testing"]), completion: nil)
        let data = diskstorage.retrieve(as: TealiumTrackRequest.self)
        XCTAssertNotNil(data?.trackDictionary["hello"], "data unexpectedly missing")
        XCTAssertEqual(data?.trackDictionary["hello"] as! String, "testing", "unexpected data retrieved")
    }

    func testAppend() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        diskstorage.save(TealiumTrackRequest(data: ["hello": "testing"]), completion: nil)
        diskstorage.append(TealiumTrackRequest(data: ["newkey": "testing"])) { _, _, _ in
            let data = diskstorage.retrieve(as: TealiumTrackRequest.self)
            XCTAssertNotNil(data?.trackDictionary["hello"], "data unexpectedly missing")
            XCTAssertEqual(data?.trackDictionary["hello"] as? String, "testing", "unexpected data retrieved")
            XCTAssertNotNil(data?.trackDictionary["newkey"], "data unexpectedly missing")
            XCTAssertEqual(data?.trackDictionary["newkey"] as! String, "testing", "unexpected data retrieved")
        }
    }

}
