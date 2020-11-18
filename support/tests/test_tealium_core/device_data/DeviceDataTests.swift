//
//  DeviceDataTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest
#if canImport(UIKit)
import UIKit
#endif

class TealiumDeviceDataTests: XCTestCase {

    var deviceData: DeviceData {
        let config = testTealiumConfig.copy
        config.memoryReportingEnabled = true
        return DeviceData()
    }
    
    var deviceDataCollector: DeviceDataModule {
        let config = testTealiumConfig.copy
        config.memoryReportingEnabled = true
        let context = TestTealiumHelper.context(with: config)
        return DeviceDataModule(context: context, delegate: nil, diskStorage: nil, completion: { result in })
    }
    
    var deviceDataCollectorMemoryDisabled: DeviceDataModule {
        let config = testTealiumConfig.copy
        config.memoryReportingEnabled = false
        let context = TestTealiumHelper.context(with: config)
        return DeviceDataModule(context: context, delegate: nil, diskStorage: nil, completion: { result in })
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBatteryPercent() {
        let percent = DeviceData.batteryPercent
        #if os (iOS)
        #if targetEnvironment(simulator)
        XCTAssertEqual(percent, "-100.0")
        #else
        XCTAssertNotEqual(percent, "-100.0")
        XCTAssertNotEqual(percent, "")
        #endif
        #else
        XCTAssertEqual(percent, TealiumValue.unknown)
        #endif
    }
    
    func testIsCharging() {
        let isCharging = DeviceData.isCharging
        #if os (iOS)
        #if targetEnvironment(simulator)
        XCTAssertEqual(isCharging, TealiumValue.unknown)
        #else
        XCTAssertNotEqual(isCharging, TealiumValue.unknown)
        #endif
        #else
        XCTAssertEqual(isCharging, TealiumValue.unknown)
        #endif
    }
    
    func testCPUType() {
        let cpu = deviceData.cpuType
        #if targetEnvironment(simulator)
        XCTAssertEqual(cpu, "x86")
        #elseif os(OSX)
        XCTAssertEqual(cpu, "x86")
        #else
        XCTAssertNotEqual(cpu, "x86")
        #endif
        XCTAssertNotEqual(cpu, TealiumValue.unknown)
    }
    
    func testIsoLanguage() {
        let isoLanguage = DeviceData.iso639Language
        XCTAssertTrue(isoLanguage.starts(with: "en"))
    }
    
    func testResolution() {
        let resolution = DeviceData.resolution
        #if os(OSX)
        XCTAssertEqual(resolution, TealiumValue.unknown)
        #else
        let res = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", height, width)
        XCTAssertEqual(stringRes, resolution)
        #endif
    }
    
    func testOrientation() {
        let orientation = deviceData.orientation
        #if os(iOS)
        #if targetEnvironment(simulator)
        XCTAssertEqual([DeviceDataKey.orientation: "Portrait",
                        DeviceDataKey.fullOrientation: "unknown"
        ], orientation)
        #else
        XCTAssertEqual([TealiumDeviceDataKey.orientation: "Portrait",
                TealiumDeviceDataKey.fullOrientation: "Face Up"
        ], orientation)
        #endif
        #else
        XCTAssertEqual([DeviceDataKey.orientation: TealiumValue.unknown,
                DeviceDataKey.fullOrientation: TealiumValue.unknown
        ], orientation)
        #endif
    }
    
    func testOSBuild() {
        XCTAssertEqual(DeviceData.oSBuild, Bundle.main.infoDictionary?["DTSDKBuild"] as! String)
    }
    
    func testOSVersion() {
        let osVersion = DeviceData.oSVersion
        #if os(iOS)
        XCTAssertEqual(osVersion, UIDevice.current.systemVersion)
        #elseif os(OSX)
        XCTAssertEqual(osVersion, ProcessInfo.processInfo.operatingSystemVersionString)
        #elseif os(tvOS)
        XCTAssertEqual(osVersion, UIDevice.current.systemVersion)
        #endif
        XCTAssertNotEqual(osVersion, TealiumValue.unknown)
    }
    
    func testOSName() {
        let osName = DeviceData.oSName
        #if os(iOS)
        XCTAssertEqual(osName, "iOS")
        #elseif os(OSX)
        XCTAssertEqual(osName, "macOS")
        #elseif os(tvOS)
        XCTAssertEqual(osName, "tvOS")
        #endif
        XCTAssertNotEqual(osName, TealiumValue.unknown)
    }
    
    func testPlatform() {
        guard let platform = deviceDataCollector.enableTimeData["platform"] as? String else {
            XCTFail("`platform` should be defined")
            return
        }
        #if os(iOS)
        XCTAssertEqual(platform, "ios")
        #elseif os(OSX)
        XCTAssertEqual(platform, "macos")
        #elseif os(tvOS)
        XCTAssertEqual(platform, "tvos")
        #endif
        XCTAssertNotEqual(platform, TealiumValue.unknown)
    }
    
    func testCarrierInfo() {
        let simulatorCarrierInfo = [
            DeviceDataKey.carrierMNC: "00",
            DeviceDataKey.carrierMCC: "000",
            DeviceDataKey.carrierISO: "us",
            DeviceDataKey.carrier: "simulator",
        ]
        
        let retrievedCarrierInfo = DeviceData.carrierInfo
        #if os(iOS)
        #if targetEnvironment(simulator)
        XCTAssertEqual(simulatorCarrierInfo, retrievedCarrierInfo)
        #else
        XCTAssertNotEqual("", retrievedCarrierInfo[TealiumDeviceDataKey.carrierMNC]!)
        XCTAssertNotEqual("", retrievedCarrierInfo[TealiumDeviceDataKey.carrierMCC]!)
        XCTAssertNotEqual("", retrievedCarrierInfo[TealiumDeviceDataKey.carrierISO]!)
        XCTAssertNotEqual("", retrievedCarrierInfo[TealiumDeviceDataKey.carrier]!)
        #endif
        #endif
    }
    
    func testModel() {
        let basicModel = deviceData.basicModel
        let fullModel = deviceData.model
        #if os(OSX)
        XCTAssertEqual(basicModel, "x86_64")
        XCTAssertEqual(fullModel["device_type"]!, "x86_64")
        XCTAssertEqual(fullModel["model_name"]!, "mac")
        XCTAssertEqual(fullModel["device"]!, "mac")
        XCTAssertEqual(fullModel["model_variant"]!, "mac")
        #else
        
        #if targetEnvironment(simulator)
        XCTAssertEqual("x86_64", basicModel)
        XCTAssertEqual(fullModel, ["device_type": "x86_64",
                                   "model_name": "Simulator",
                                   "device": "Simulator",
                                   "model_variant": "64-bit"])
        #else
        XCTAssertNotEqual("x86_64", basicModel)
        XCTAssertNotEqual("", basicModel)
        XCTAssertNotEqual(fullModel["device_type"]!, "x86_64")
        XCTAssertNotEqual(fullModel["device_type"]!, "")
        
        XCTAssertNotEqual(fullModel["model_name"]!, "Simulator")
        XCTAssertNotEqual(fullModel["model_name"]!, "")
        
        XCTAssertNotEqual(fullModel["device"]!, "Simulator")
        XCTAssertNotEqual(fullModel["device"]!, "")
        
        XCTAssertNotEqual(fullModel["model_variant"]!, "64-bit")
        XCTAssertNotEqual(fullModel["model_variant"]!, "")
        #endif
        #endif
    }
    
    func testGetMemoryUsage() {
        let memoryUsage = deviceData.memoryUsage
        XCTAssertNotEqual(memoryUsage["memory_free"]!, "")
        XCTAssertNotEqual(memoryUsage["memory_inactive"]!, "")
        
        XCTAssertNotEqual(memoryUsage["memory_wired"]!, "")
        XCTAssertNotEqual(memoryUsage["memory_active"]!, "")
        
        XCTAssertNotEqual(memoryUsage["memory_compressed"]!, "")
        XCTAssertNotEqual(memoryUsage["memory_physical"]!, "")
        
        XCTAssertNotEqual(memoryUsage["app_memory_usage"]!, "")
    }
    
    func testDeviceDataCollectorMemoryEnabled() {
        let collector = deviceDataCollector
        let data = collector.data as! [String: String]
        XCTAssertNotEqual(data["memory_free"]!, "")
        XCTAssertNotEqual(data["memory_inactive"]!, "")
        XCTAssertNotEqual(data["memory_wired"]!, "")
        XCTAssertNotEqual(data["memory_active"]!, "")
        XCTAssertNotEqual(data["memory_compressed"]!, "")
        XCTAssertNotEqual(data["memory_physical"]!, "")
        XCTAssertNotEqual(data["app_memory_usage"]!, "")
        XCTAssertNotEqual(data["device_architecture"]!, "")
        XCTAssertNotEqual(data["device_os_build"]!, "")
        XCTAssertNotEqual(data["device_cputype"]!, "")
        XCTAssertNotEqual(data["device_manufacturer"]!, "")
        XCTAssertNotEqual(data["device_type"]!, "")
        XCTAssertNotEqual(data["model_name"]!, "")
        XCTAssertNotEqual(data["device"]!, "")
        XCTAssertNotEqual(data["model_variant"]!, "")
        XCTAssertNotEqual(data["device_os_version"]!, "")
        XCTAssertNotEqual(data["os_name"]!, "")
        XCTAssertNotEqual(data["platform"]!, "")
        XCTAssertNotEqual(data["device_resolution"]!, "")
        XCTAssertNotEqual(data["device_battery_percent"]!, "")
        XCTAssertNotEqual(data["device_language"]!, "")
        XCTAssertNotEqual(data["device_orientation"]!, "")
        XCTAssertNotEqual(data["device_orientation_extended"]!, "")
        #if os(iOS)
        XCTAssertNotEqual(data["carrier_mnc"]!, "")
        XCTAssertNotEqual(data["carrier_mcc"]!, "")
        XCTAssertNotEqual(data["carrier_iso"]!, "")
        XCTAssertNotEqual(data["carrier"]!, "")
        #endif
    }
    
    func testDeviceDataCollectorMemoryDisabled() {
        let collector = deviceDataCollectorMemoryDisabled
        let data = collector.data as! [String: String]
        XCTAssertNil(data["memory_free"])
        XCTAssertNil(data["memory_inactive"])
        XCTAssertNil(data["memory_wired"])
        XCTAssertNil(data["memory_active"])
        XCTAssertNil(data["memory_compressed"])
        XCTAssertNil(data["memory_physical"])
        XCTAssertNil(data["app_memory_usage"])
    }
}
