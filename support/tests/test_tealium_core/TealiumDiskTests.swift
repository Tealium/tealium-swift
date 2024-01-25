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
    let legacyJsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "Infinity", nan: "NaN")
        return encoder
    }()
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

    func testSaveBigDouble() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        let value: Double = Double.greatestFiniteMagnitude
        diskstorage.save(TealiumTrackRequest(data: ["double": value]), completion: nil)
        let data = diskstorage.retrieve(as: TealiumTrackRequest.self)
        XCTAssertNotNil(data?.trackDictionary["double"], "data unexpectedly missing")
        XCTAssertEqual(data?.trackDictionary["double"] as! Double, value, "unexpected data retrieved")
    }

    func testFilePath() {
        let config = TealiumConfig(account: "account", profile: "profile", environment: "env")
        let path = TealiumDiskStorage.filePath(forConfig: config, name: "name")
        XCTAssertEqual(path, "account.profile/name/")
    }
    
    func testSaveDates() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        let value: Date = Date()
        diskstorage.save(value, completion: nil)
        let data = diskstorage.retrieve(as: Date.self)
        XCTAssertNotNil(data, "data unexpectedly missing")
    }

    func testMigrationDates() throws {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        let value = Date()
        do {
            try Disk.save(value, to: diskstorage.defaultDirectory, as: diskstorage.filePath(diskstorage.module), encoder: legacyJsonEncoder)
        } catch {
            XCTFail("Save on disk failed due to error \(error.localizedDescription)")
        }
        let data = diskstorage.retrieve(as: Date.self)
        XCTAssertNotNil(data, "data unexpectedly missing")
    }
    
    class CustomObjectWithDate: Codable {
        let date: Date
        init(_ date: Date) {
            self.date = date
        }
    }

    func testMigrationDatesInContainer() throws {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        let value = CustomObjectWithDate(Date())
        do {
            try Disk.save(value, to: diskstorage.defaultDirectory, as: diskstorage.filePath(diskstorage.module), encoder: legacyJsonEncoder)
        } catch {
            XCTFail("Save on disk failed due to error \(error.localizedDescription)")
        }
        let data = diskstorage.retrieve(as: CustomObjectWithDate.self)
        XCTAssertNotNil(data, "data unexpectedly missing")
    }
    
    func testDecodeWorksForLegacyAndNewDates() throws {
        let value = Date()
        let legacyEncoded = try legacyJsonEncoder.encode(value)
        let newEncoded = try Tealium.jsonEncoder.encode(value)
        XCTAssertNoThrow(try Disk.decode(Tealium.jsonDecoder, type: Date.self, from: legacyEncoded))
        XCTAssertNoThrow(try Disk.decode(Tealium.jsonDecoder, type: Date.self, from: newEncoded))
    }
    
    func testDecodeWorksForLegacyAndNewDatesInContainer() throws {
        let value = CustomObjectWithDate(Date())
        let legacyEncoded = try legacyJsonEncoder.encode(value)
        let newEncoded = try Tealium.jsonEncoder.encode(value)
        XCTAssertNoThrow(try Disk.decode(Tealium.jsonDecoder, type: CustomObjectWithDate.self, from: legacyEncoded))
        XCTAssertNoThrow(try Disk.decode(Tealium.jsonDecoder, type: CustomObjectWithDate.self, from: newEncoded))
    }

    func testDiskStorageDefaultLocation() {
        let diskstorage = TealiumDiskStorage(config: config, forModule: "Tests")
        #if os(tvOS)
        XCTAssertEqual(diskstorage.currentDirectory, .caches)
        #else
        XCTAssertEqual(diskstorage.currentDirectory, .applicationSupport)
        #endif
    }
}
