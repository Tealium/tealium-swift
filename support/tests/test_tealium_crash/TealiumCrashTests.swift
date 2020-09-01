//
//  TealiumCrashTests.swift
//  tealium-swift-tests-ios
//
//  Created by Jonathan Wong on 2/12/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

//@testable import TealiumAppData
@testable import TealiumCore
@testable import TealiumCrash
@testable import TealiumCrashReporteriOS
//@testable import DeviceData
//@testable import TealiumVolatileData
import XCTest

class TealiumCrashTests: XCTestCase {

    var mockTimestampCollection: TimestampCollection!
    var mockAppDataCollection: AppDataCollection!
    var mockDeviceDataCollection: DeviceDataCollection!

    override func setUp() {
        super.setUp()
        mockTimestampCollection = MockTimestampCollection()
        mockAppDataCollection = MockTealiumAppDataCollection()
        mockDeviceDataCollection = MockDeviceDataCollection()
    }

    override func tearDown() {
        mockTimestampCollection = nil
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

        XCTAssertEqual(DeviceDataValue.unknown, crash.memoryUsage)
    }

    func testMemoryAvailableReturnsUnknownIfMemoryFreeIsNil() {
        let crashReport = TEALPLCrashReport()
        let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: mockDeviceDataCollection)

        XCTAssertEqual(DeviceDataValue.unknown, crash.deviceMemoryAvailable)
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
                                    CrashKey.uuid,
                                    CrashKey.deviceMemoryUsage,
                                    CrashKey.deviceMemoryAvailable,
                                    CrashKey.deviceOsBuild,
                                    TealiumKey.appBuild,
                                    CrashKey.processId,
                                    CrashKey.processPath,
                                    CrashKey.parentProcess,
                                    CrashKey.parentProcessId,
                                    CrashKey.exceptionName,
                                    CrashKey.exceptionReason,
                                    CrashKey.signalCode,
                                    CrashKey.signalName,
                                    CrashKey.signalAddress,
                                    CrashKey.libraries,
                                    CrashKey.threads
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

public class MockDeviceDataCollection: DeviceDataCollection {
    public var orientation: [String: String] {
        return orientationDictionary
    }

    public var model: [String: String] {
        return modelDictionary
    }

    public var basicModel: String {
        basicModelProperty
    }

    public var cpuType: String {
        architecture
    }

    public var memoryUsage = [String: String]()
    var orientationDictionary = [String: String]()
    var modelDictionary = [String: String]()
    var basicModelProperty = ""
    var architecture: String = ""

    public func getMemoryUsage() -> [String: String] {
        return memoryUsage
    }
}

class MockTimestampCollection: TimestampCollection {
    var currentTimeStamps: [String: Any] {
        ["test": "1"]
    }
}

class MockTealiumAppDataCollection: AppDataCollection {
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
