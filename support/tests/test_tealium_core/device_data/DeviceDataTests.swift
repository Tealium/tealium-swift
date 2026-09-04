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

    var deviceDataCollectorScreenDisabled: DeviceDataModule {
        let config = testTealiumConfig.copy
        config.screenReportingEnabled = false
        let context = TestTealiumHelper.context(with: config)
        return DeviceDataModule(context: context, delegate: nil, diskStorage: nil, completion: { result in })
    }

    var deviceDataCollectorBatteryDisabled: DeviceDataModule {
        let config = testTealiumConfig.copy
        config.batteryReportingEnabled = false
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
        #if targetEnvironment(simulator) || os(OSX)
        let desktopCPUs = ["x86", "ARM64e"]
        XCTAssertTrue(desktopCPUs.contains(cpu))
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
        let res = UIScreen.main.fixedCoordinateSpace.bounds
        let scale = UIScreen.main.scale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", width, height)
        XCTAssertEqual(stringRes, resolution)
        #endif
    }
    
    func testLogicalResolution() {
        let resolution = DeviceData.logicalResolution
        #if os(OSX)
        XCTAssertEqual(resolution, TealiumValue.unknown)
        #else
        let res = UIScreen.main.fixedCoordinateSpace.bounds
        let width = res.width
        let height = res.height
        let stringRes = String(format: "%.0fx%.0f", width, height)
        XCTAssertEqual(stringRes, resolution)
        #endif
    }
    
    func testOrientation() {
        let orientation = deviceData.orientation
        #if os(iOS)
        #if targetEnvironment(simulator)
        XCTAssertEqual([TealiumDataKey.orientation: "Portrait",
                        TealiumDataKey.fullOrientation: "unknown"
        ], orientation)
        #else
        XCTAssertEqual([TealiumDeviceDataKey.orientation: "Portrait",
                TealiumDeviceDataKey.fullOrientation: "Face Up"
        ], orientation)
        #endif
        #else
        XCTAssertEqual([TealiumDataKey.orientation: TealiumValue.unknown,
                        TealiumDataKey.fullOrientation: TealiumValue.unknown
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
        #if os(iOS)
        #if targetEnvironment(simulator)
        let simulatorCarrierInfo = [
            TealiumDataKey.carrierMNC: "00",
            TealiumDataKey.carrierMCC: "000",
            TealiumDataKey.carrierISO: "us",
            TealiumDataKey.carrier: "simulator",
        ]
        
        let retrievedCarrierInfo = DeviceData.carrierInfo

        XCTAssertEqual(simulatorCarrierInfo, retrievedCarrierInfo)
        #else
        let retrievedCarrierInfo = DeviceData.carrierInfo
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
        #if targetEnvironment(simulator)
        XCTAssertEqual("x86_64", basicModel)
        XCTAssertEqual(fullModel, ["device_type": "x86_64",
                                   "model_name": "Simulator",
                                   "device": "Simulator",
                                   "model_variant": "64-bit"])
        
        #elseif os(OSX)
        XCTAssertString(basicModel, contains: "Mac")
        XCTAssertString(fullModel["device_type"], contains: "Mac")
        XCTAssertString(fullModel["model_name"], contains: "Mac")
        XCTAssertString(fullModel["device"], contains: "Mac")
        XCTAssertEqual(fullModel["model_variant"]!, "")
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
    }
    
    func testGetMemoryUsage() {
        let memoryUsage = deviceData.memoryUsage
        XCTAssertNotNil(memoryUsage["memory_free"])
        XCTAssertNotNil(memoryUsage["memory_inactive"])

        XCTAssertNotNil(memoryUsage["memory_wired"])
        XCTAssertNotNil(memoryUsage["memory_active"])

        XCTAssertNotNil(memoryUsage["memory_compressed"])
        XCTAssertNotNil(memoryUsage["memory_physical"])

        XCTAssertNotNil(memoryUsage["app_memory_usage"])
    }
    
    func testDeviceDataCollectorMemoryEnabled() {
        let collector = deviceDataCollector
        guard let data = collector.data else {
            XCTFail("Collector data should not be nil")
            return
        }
        XCTAssertNotNil(data["memory_free"] as? Int)
        XCTAssertNotNil(data["memory_inactive"] as? Int)
        XCTAssertNotNil(data["memory_wired"] as? Int)
        XCTAssertNotNil(data["memory_active"] as? Int)
        XCTAssertNotNil(data["memory_compressed"] as? Int)
        XCTAssertNotNil(data["memory_physical"] as? Int)
        XCTAssertNotNil(data["app_memory_usage"] as? Int)
        XCTAssertNotEqual(data["device_architecture"] as? String, "")
        XCTAssertNotEqual(data["device_os_build"] as? String, "")
        XCTAssertNotEqual(data["device_cputype"] as? String, "")
        XCTAssertNotEqual(data["device_manufacturer"] as? String, "")
        XCTAssertNotEqual(data["device_type"] as? String, "")
        XCTAssertNotEqual(data["model_name"] as? String, "")
        XCTAssertNotEqual(data["device"] as? String, "")
        XCTAssertNotEqual(data["device_os_version"] as? String, "")
        XCTAssertNotEqual(data["os_name"] as? String, "")
        XCTAssertNotEqual(data["platform"] as? String, "")
        XCTAssertNotEqual(data["device_resolution"] as? String, "")
        XCTAssertNotEqual(data["device_logical_resolution"] as? String, "")
        XCTAssertNotEqual(data["device_battery_percent"] as? String, "")
        XCTAssertNotEqual(data["device_language"] as? String, "")
        XCTAssertNotEqual(data["device_orientation"] as? String, "")
        XCTAssertNotEqual(data["device_orientation_extended"] as? String, "")
        #if os(iOS)
        XCTAssertNotEqual(data["carrier_mnc"] as? String, "")
        XCTAssertNotEqual(data["carrier_mcc"] as? String, "")
        XCTAssertNotEqual(data["carrier_iso"] as? String, "")
        XCTAssertNotEqual(data["carrier"] as? String, "")
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

    func testDeviceDataCollectorScreenDisabled() {
        let collector = deviceDataCollectorScreenDisabled
        let data = collector.data as! [String: String]
        XCTAssertNil(data["device_orientation"])
        XCTAssertNil(data["device_orientation_extended"])
        XCTAssertNil(data["device_resolution"])
        XCTAssertNil(data["device_logical_resolution"])
    }

    func testDeviceDataCollectorScreenEnabled() {
        let collector = deviceDataCollector
        guard let data = collector.data else {
            XCTFail("Collector data should not be nil")
            return
        }
        XCTAssertNotEqual(data["device_orientation"] as? String, "")
        XCTAssertNotEqual(data["device_orientation_extended"] as? String, "")
        XCTAssertNotEqual(data["device_resolution"] as? String, "")
        XCTAssertNotEqual(data["device_logical_resolution"] as? String, "")
    }

    func testDeviceDataCollectorBatteryDisabled() {
        let collector = deviceDataCollectorBatteryDisabled
        let data = collector.data as! [String: String]
        XCTAssertNil(data["device_battery_percent"])
        XCTAssertNil(data["device_ischarging"])
    }

    func testDeviceDataCollectorBatteryEnabled() {
        let collector = deviceDataCollector
        guard let data = collector.data else {
            XCTFail("Collector data should not be nil")
            return
        }
        XCTAssertNotEqual(data["device_battery_percent"] as? String, "")
        XCTAssertNotEqual(data["device_ischarging"] as? String, "")
    }
}
