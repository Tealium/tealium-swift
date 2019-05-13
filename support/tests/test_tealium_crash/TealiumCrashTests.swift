//
//  TealiumCrashTests.swift
//  tealium-swift-tests-ios
//
//  Created by Jonathan Wong on 2/12/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumAppData
@testable import TealiumDeviceData
@testable import TealiumVolatileData
@testable import TealiumCrash
@testable import TealiumCrashReporteriOS

class TealiumCrashTests: XCTestCase {

    var mockVolatileDataCollection: TealiumVolatileDataCollection!
    var mockAppDataCollection: TealiumAppDataCollection!
    var mockDeviceDataCollection: TealiumDeviceDataCollection!

    override func setUp() {
        super.setUp()
        mockVolatileDataCollection = MockTealiumVolatileDataCollection()
        mockAppDataCollection = MockTealiumAppDataCollection()
        mockDeviceDataCollection = MockTealiumDeviceDataCollection()
    }

    override func tearDown() {
        mockVolatileDataCollection = nil
        mockAppDataCollection = nil
        mockDeviceDataCollection = nil
        super.tearDown()
    }

    func testCrashUuidNotNil() {
        let crashReport = TEALPLCrashReport()
        let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)

        XCTAssertNotNil(crash.uuid, "crash.uuid should not be nil")
    }

    func testCrashUuidsUnique() {
        let crashReport = TEALPLCrashReport()
        let crash1 = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)
        let crash2 = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)

        XCTAssertNotEqual(crash1.uuid, crash2.uuid, "crash.uuid should be unique between crash instances")
    }

    func testMemoryUsageReturnsUnknownIfAppMemoryUsageIsNil() {
        let crashReport = TEALPLCrashReport()
        let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)

        XCTAssertEqual(TealiumDeviceDataValue.unknown, crash.memoryUsage)
    }

    func testMemoryAvailableReturnsUnknownIfMemoryFreeIsNil() {
        let crashReport = TEALPLCrashReport()
        let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)

        XCTAssertEqual(TealiumDeviceDataValue.unknown, crash.deviceMemoryAvailable)
    }

    func testThreadsReturnsCrashedIfTruncated() {
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(forResource: "index_out_of_bounds", withExtension: "plcrash") {
            do {
                let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedRead)
                let crashReport = try TEALPLCrashReport(data: data)
                let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)
                let result = crash.threads(truncate: true)
                XCTAssertEqual(1, result.count)
            } catch _ {
                XCTFail("Error running test")
            }
        }
    }

    func testLibrariesReturnsFirstLibraryIfTruncated() {
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(forResource: "index_out_of_bounds", withExtension: "plcrash") {
            do {
                let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedRead)
                let crashReport = try TEALPLCrashReport(data: data)
                let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)
                let result = crash.libraries(truncate: true)
                XCTAssertEqual(1, result.count)
            } catch _ {
                XCTFail("Error running test")
            }
        }
    }

    func testGetDataCrashKeys() {
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(forResource: "live_report", withExtension: "plcrash") {
            do {
                let data = try Data(contentsOf: url, options: Data.ReadingOptions.mappedRead)
                let crashReport = try TEALPLCrashReport(data: data)
                let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)
                let expectedKeys = [TealiumKey.event,
                                    TealiumCrashKey.uuid,
                                    TealiumCrashKey.deviceMemoryUsage,
                                    TealiumCrashKey.deviceMemoryAvailable,
                                    TealiumCrashKey.deviceOsBuild,
                                    TealiumAppDataKey.build,
                                    TealiumCrashKey.processId,
                                    TealiumCrashKey.processPath,
                                    TealiumCrashKey.parentProcess,
                                    TealiumCrashKey.parentProcessId,
                                    TealiumCrashKey.exceptionName,
                                    TealiumCrashKey.exceptionReason,
                                    TealiumCrashKey.signalCode,
                                    TealiumCrashKey.signalName,
                                    TealiumCrashKey.signalAddress,
                                    TealiumCrashKey.libraries,
                                    TealiumCrashKey.threads,
                ]
                let result = crash.getData()
                for key in expectedKeys {
                    print(key)
                    XCTAssertNotNil(result[key])
                }
            } catch _ {
                XCTFail("Error running test")
            }
        }
    }
}

public class MockTealiumDeviceDataCollection: TealiumDeviceDataCollection {

    var memoryUsage = [String: String]()
    var orientationDictionary = [String: String]()
    var modelDictionary = [String: String]()
    var basicModelProperty = ""
    var architecture: String = ""

    public func getMemoryUsage() -> [String: String] {
        return memoryUsage
    }

    public func orientation() -> [String: String] {
        return orientationDictionary
    }

    public func model() -> [String: String] {
        return modelDictionary
    }

    public func basicModel() -> String {
        return basicModelProperty
    }

    public func cpuType() -> String {
        return architecture
    }
}

class MockTealiumVolatileDataCollection: TealiumVolatileDataCollection {
    func currentTimeStamps() -> [String: Any] {
        return ["test": "1"]
    }
}

class MockTealiumAppDataCollection: TealiumAppDataCollection {
    var uuid: String?
    var appName: String?
    var appVersion: String?
    var appRdns: String?
    var appBuild: String?

    func name() -> String? {
        return appName
    }

    func rdns() -> String? {
        return appRdns
    }

    func version() -> String? {
        return appVersion
    }

    func build() -> String? {
        return appBuild
    }
}
