//
//  TealiumVolatileDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumVolatileDataTests: XCTestCase {

    var volatileData: TealiumVolatileData?

    override func setUp() {
        super.setUp()

        let helper = TestTealiumHelper()
        let enableRequest = TealiumEnableRequest(config: helper.getConfig())
        let module = TealiumVolatileDataModule(delegate: nil)
        module.enable(enableRequest)

        volatileData = module.volatileData
    }

    override func tearDown() {
        volatileData = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAdd() {
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }
        let initialDataCount = volatileData.getData().count
        let data = ["a": "1", "b": "2"]
        volatileData.add(data: data)

        let result = volatileData.getData()
        XCTAssertEqual(result.count, initialDataCount + data.count)

        for (key, _) in data {
            XCTAssertEqual(data[key], result[key] as? String)
        }
    }

    func testGetDataInitialValues() {
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }
        let result = volatileData.getData()

        // initial static static when module is enabled
        XCTAssertNotNil(result[TealiumKey.account] as? String)
        XCTAssertNotNil(result[TealiumKey.profile] as? String)
        XCTAssertNotNil(result[TealiumKey.environment] as? String)
        XCTAssertNotNil(result[TealiumKey.libraryName] as? String)
        XCTAssertNotNil(result[TealiumKey.libraryVersion] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.sessionId] as? String)

        // getData() method
        XCTAssertNotNil(result[TealiumVolatileDataKey.random] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampEpoch] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestamp] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampLocal] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampUnix] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampOffset] as? String)
    }

    func testGetRandomWithIterator() {
        var randomNumbers = [String]()
        let regex = try! NSRegularExpression(pattern: "^[0-9]{16}$", options: [])

        for _ in 1...100 {
            let random = TealiumVolatileData.getRandom(length: 16)
            if randomNumbers.contains(random) == true {
                XCTFail("Duplicate random number")
            } else {
                let matches = regex.numberOfMatches(in: random, options: [], range: NSRange(location: 0, length: random.count))
                print("matches here is : \(matches)")
                if matches != 1 {
                    print ("random number is :::: \(random)")
                    XCTFail("Random number is not a 16 digits long")
                }
                randomNumbers.append(random)
            }
        }
    }

    func testNewSessionIdsAreUnique() {
        let sessionId = TealiumVolatileData.newSessionId()
        sleep(1)
        let sessionId2 = TealiumVolatileData.newSessionId()

        XCTAssertNotEqual(sessionId, sessionId2)
    }

    func testDeleteDataRemovesData() {
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }
        let initialData = volatileData.getData()
        volatileData.deleteData(forKeys: [TealiumVolatileDataKey.sessionId, TealiumKey.libraryVersion])
        let result = volatileData.getData()

        XCTAssertEqual(initialData.count - 2, result.count, "Counts did not match")
        XCTAssertNil(result[TealiumVolatileDataKey.sessionId], "sessionId should be nil")
        XCTAssertNil(result[TealiumKey.libraryVersion], "libraryVersion should be nil")
    }

    func testResetSessionIdGeneratesNewSessionId() {
        guard let volatileData = volatileData else {
            XCTFail("TealiumVolatileData did not spin up correctly")
            return
        }

        let sessionId = volatileData.getData()[TealiumVolatileDataKey.sessionId] as? String
        sleep(1)
        volatileData.resetSessionId()
        let resultSessionId = volatileData.getData()[TealiumVolatileDataKey.sessionId] as? String

        XCTAssertNotEqual(sessionId, resultSessionId, "sessionIds should be different")
    }

    func testVolatileData() {
        // TODO: test arrays and other value types
        let testData = [
            "a": "1",
            "b": "2"
        ] as [String: Any]

        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }

        volatileData.add(data: testData as [String: AnyObject])

        let data = volatileData.getData()

        XCTAssertTrue(testData.contains(otherDictionary: data), "VolatileData: \(volatileData)")

        volatileData.deleteData(forKeys: ["a", "b"])

        let volatileDataPostDelete = volatileData.getData()

        XCTAssertFalse(volatileDataPostDelete.contains(otherDictionary: testData), "VolatileData: \(volatileDataPostDelete)")
    }

    func testCurrentTimeStamps() {
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }
        let result = volatileData.getData()

        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampEpoch] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestamp] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampLocal] as? String)
        XCTAssertNotNil(result[TealiumVolatileDataKey.timestampUnix] as? String)
    }

    func testDeleteAll() {
        // TODO: test arrays and other value types
        let testData = [
            "a": "1",
            "b": "2"] as [String: Any]

        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up expectedly.")
            return
        }

        volatileData.add(data: testData as [String: AnyObject])

        let data = volatileData.getData()

        XCTAssertTrue(testData.contains(otherDictionary: data), "VolatileData: \(volatileData)")

        volatileData.deleteAllData()

        let volatileDataPostDelete = volatileData.getData()

        XCTAssertFalse(volatileDataPostDelete.contains(otherDictionary: testData), "VolatileData: \(volatileDataPostDelete)")
    }

}
