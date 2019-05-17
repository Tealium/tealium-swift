//
//  TealiumDeviceDataModuleTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/6/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumDeviceDataModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?
    var deviceDataModule: TealiumDeviceDataModule?
    var trackData: [String: Any]?

    override func setUp() {
        super.setUp()
        deviceDataModule = TealiumDeviceDataModule(delegate: nil)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {

        deviceDataModule = nil
        trackData = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testForFailingRequests() {
        let helper = TestTealiumHelper()
        let module = TealiumDeviceDataModule(delegate: nil)

        let failing = helper.failingRequestsFor(module: module)
        XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "allRequestsReturn")
        let helper = TestTealiumHelper()
        let module = TealiumDeviceDataModule(delegate: nil)

        helper.modulesReturnsMinimumProtocols(module: module) { _, failing in

            expectation.fulfill()
            XCTAssert(failing.count == 0, "Unexpected failing requests: \(failing)")
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testTrack() {
        let expectation = self.expectation(description: "deviceDataTrack")
        let module = TealiumDeviceDataModule(delegate: self)
        let request = TealiumEnableRequest(config: TestTealiumHelper().getConfig(), enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true

        let track = TealiumTrackRequest(data: [:]) { _, _, _ in
            expectation.fulfill()

            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }
            #if os(iOS)
            let expectedKeys = [
                "device_architecture",
                "cpu_architecture",
                "os_build",
                "device_os_build",
                "device_cputype",
                "cpu_type",
                "model_name",
                "model_variant",
                "device_os_version",
                "os_version",
                "platform",
                "os_name",
                "device_resolution",
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "device_language",
                "user_locale",
                "app_orientation",
                "device_orientation",
                "device_orientation_extended",
                "carrier",
                "carrier_mnc",
                "carrier_mcc",
                "carrier_iso",
                "network_name",
                "network_mnc",
                "network_mcc",
                "network_iso_country_code",
            ]
            #else
            let expectedKeys = [
                "device_architecture",
                "cpu_architecture",
                "os_build",
                "device_os_build",
                "device_cputype",
                "cpu_type",
                "model_name",
                "model_variant",
                "device_os_version",
                "os_version",
                "platform",
                "os_name",
                "device_resolution",
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "user_locale",
                "device_orientation",
                "device_orientation_extended",
            ]
            #endif

            let unexpectedKeys = [
                "memory_free",
                "memory_wired",
                "memory_active",
                "memory_inactive",
                "memory_compressed",
                "memory_physical",
                "app_memory_usage",
            ]

            for key in expectedKeys where trackData[key] == nil {
                XCTFail("\nKey:\(key) was missing from tracking call. Tracking data: \(trackData)\n")
            }

            for key in unexpectedKeys where trackData[key] != nil {
                XCTFail("\nKey:\(key) was unexpectedly present in tracking call. Tracking data: \(trackData)\n")
            }
        }

        module.track(track)

        self.waitForExpectations(timeout: 1.0, handler: nil)

    }

    func testTrackWithMemory() {
        let expectation = self.expectation(description: "deviceDataTrack")
        let module = TealiumDeviceDataModule(delegate: self)
        let config = TestTealiumHelper().getConfig()
        config.setMemoryReportingEnabled(true)
        let request = TealiumEnableRequest(config: config, enableCompletion: nil)
        module.enable(request)
        module.isEnabled = true

        let track = TealiumTrackRequest(data: [:]) { _, _, _ in
            expectation.fulfill()

            guard let trackData = self.trackData else {
                XCTFail("No track data detected from test.")
                return
            }
            #if os(iOS)
            let expectedKeys = [
                "device_architecture",
                "cpu_architecture",
                "os_build",
                "device_os_build",
                "device_cputype",
                "cpu_type",
                "model_name",
                "model_variant",
                "device_os_version",
                "os_version",
                "platform",
                "os_name",
                "device_resolution",
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "user_locale",
                "app_orientation",
                "device_orientation",
                "device_orientation_extended",
                "carrier",
                "carrier_mnc",
                "carrier_mcc",
                "carrier_iso",
                "network_name",
                "network_mnc",
                "network_mcc",
                "network_iso_country_code",
                "memory_free",
                "memory_wired",
                "memory_active",
                "memory_inactive",
                "memory_compressed",
                "memory_physical",
                "app_memory_usage",
            ]
            #else
            let expectedKeys = [
                "device_architecture",
                "cpu_architecture",
                "os_build",
                "device_os_build",
                "device_cputype",
                "cpu_type",
                "model_name",
                "model_variant",
                "device_os_version",
                "os_version",
                "platform",
                "os_name",
                "device_resolution",
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "user_locale",
                "device_orientation",
                "device_orientation_extended",
                "memory_free",
                "memory_wired",
                "memory_active",
                "memory_inactive",
                "memory_compressed",
                "memory_physical",
                "app_memory_usage",
            ]
            #endif

            for key in expectedKeys where trackData[key] == nil {
                XCTFail("\nKey:\(key) was missing from tracking call. Tracking data: \(trackData)\n")
            }
        }

        module.track(track)

        self.waitForExpectations(timeout: 1.0, handler: nil)

    }

    // Can only run within a sample app

    func testEnableTimeData() {
        let module = TealiumDeviceDataModule(delegate: nil)
        let allData = module.enableTimeData()
        let expectedKeys = [
            "device_architecture",
            "cpu_architecture",
            "os_build",
            "device_os_build",
            "device_cputype",
            "cpu_type",
            "model_name",
            "model_variant",
            "device_os_version",
            "os_version",
            "platform",
            "os_name",
            "device_resolution",
        ]
        for key in expectedKeys where allData[key] == nil {
            XCTFail("Missing key: \(key). Device Data: \(allData)")
        }
    }

    func testTrackTimeDataKeys() {
        let module = TealiumDeviceDataModule(delegate: nil)
        let allData = module.trackTimeData()
        #if os(iOS)
            let expectedKeys = [
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "user_locale",
                "app_orientation",
                "device_orientation",
                "device_orientation_extended",
                "carrier",
                "carrier_mnc",
                "carrier_mcc",
                "carrier_iso",
                "network_name",
                "network_mnc",
                "network_mcc",
                "network_iso_country_code",
            ]
        #else
            let expectedKeys = [
                "device_ischarging",
                "device_battery_percent",
                "battery_percent",
                "device_is_charging",
                "user_locale",
                "device_orientation",
                "device_orientation_extended",
            ]
        #endif
        for key in expectedKeys where allData[key] == nil {
            XCTFail("Missing key: \(key). Device Data: \(allData)")
        }
    }

    func testBatteryPercentValid() {
        let module = TealiumDeviceDataModule(delegate: nil)
        let allData = module.trackTimeData()
        let enableData = module.enableTimeData()
        let simulator = enableData["model_name"] as? String == "Simulator"
        if let batteryPercent = allData["battery_percent"] {
            if let bpDouble = Double(batteryPercent as! String) {
                if simulator {
                    XCTAssertTrue(batteryPercent as? String == "-100.0")
                } else {
                 XCTAssertTrue(bpDouble >= 0.0 && bpDouble <= 100.0, "Battery percentage is not valid")
                }
            }
        } else {
            XCTFail("Battery percentage missing from track call")
        }

    }

}

// For future tests
extension TealiumDeviceDataModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            trackData = process.data
            process.completion?(true,
                                nil,
                                nil)
        }
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

    }

}
