//
//  TealiumVolatileDataModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumVolatileDataModuleTests: XCTestCase {

    var module: TealiumVolatileDataModule?

    override func setUp() {
        super.setUp()

        module = TealiumVolatileDataModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        module = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumVolatileDataModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testVolatileDataKeysAvailable() {
        let config = TealiumConfig(account: TealiumTestValue.account,
                                   profile: TealiumTestValue.profile,
                                   environment: TealiumTestValue.environment,
                                   optionalData: [String: Any]() as [String: Any])

        module?.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        let volatileDataKeysExpected = [
            "tealium_account",
            "tealium_profile",
            "tealium_environment",
            "tealium_library_name",
            "tealium_library_version",
            "tealium_random",
            "tealium_session_id",
            "tealium_timestamp_epoch",
            "timestamp",
            "timestamp_local",
            "timestamp_offset",
            "timestamp_unix",
            "timestamp_unix_milliseconds",
            "event_timestamp_iso",
            "event_timestamp_local_iso",
            "event_timestamp_offset_hours",
            "event_timestamp_unix_millis",
        ]

        guard let volatileDataReturned = module?.volatileData.getData(currentData: [String: Any]()) else {
            XCTFail("No volatile data returned from test module: \(String(describing: module))")
            return
        }

        let missingKeys = TestTealiumHelper.missingKeys(fromDictionary: volatileDataReturned, keys: volatileDataKeysExpected)

        XCTAssertTrue(missingKeys.isEmpty, "\n\n Volatile data is missing keys: \(missingKeys)")
    }

    func testJoinAndLeaveTrace() {
        let config = TealiumConfig(account: TealiumTestValue.account,
                                   profile: TealiumTestValue.profile,
                                   environment: TealiumTestValue.environment,
                                   optionalData: [String: Any]() as [String: Any])

        module?.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        let traceId = "12345"
        let traceIdKey = "cp.trace_id"
        let joinTraceRequest = TealiumJoinTraceRequest(traceId: traceId)
        module?.handle(joinTraceRequest)
        XCTAssertTrue(module?.volatileData.getData()[traceIdKey] as? String == traceId, "Trace ID incorrect or missing")
        let leaveTraceRequest = TealiumLeaveTraceRequest()
        module?.handle(leaveTraceRequest)
        XCTAssertNil(module?.volatileData.getData()[traceIdKey], "Trace ID not successfully deleted")
    }

}
