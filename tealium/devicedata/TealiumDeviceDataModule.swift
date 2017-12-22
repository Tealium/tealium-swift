//
//  TealiumDeviceDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 8/3/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif
import Foundation
#if os(tvOS)
#elseif os (watchOS)
#else
import CoreTelephony
#endif
#if os(watchOS)
import WatchKit
#endif

import Darwin

private let HOST_VM_INFO64_COUNT          : mach_msg_type_number_t =
    UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

enum TealiumDeviceDataModuleKey {
    static let moduleName = "devicedata"
    static let isMemoryReportingEnabled = "com.tealium.devicedata.memory.enable"
}

enum TealiumDeviceDataValue {
    static let unknown = "unknown"
    static let appleWatch = "Apple Watch"
}

class TealiumDeviceDataModule : TealiumModule {
    
    var data = [String:Any]()
    var isMemoryEnabled = false
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDeviceDataModuleKey.moduleName,
                                   priority: 525,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        data = enableTimeData()
        let config = request.config
        isMemoryEnabled = config.isMemoryReportingEnabled()
        didFinish(request)
    }
    
    override func track(_ request: TealiumTrackRequest) {
        
        // Add device data to the data stream.
        var newData = request.data
        newData += data
        newData += trackTimeData()
        let newTrack = TealiumTrackRequest(data: newData,
                                           completion: request.completion)
        
        didFinish(newTrack)
    }
    
    
    /// Data that only needs to be retrieved once for the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func enableTimeData() -> [String : Any] {
        
        var result = [String : Any]()

        result[TealiumDeviceDataKey.architecture] = TealiumDeviceData.architecture()
        result[TealiumDeviceDataKey.osBuild] = TealiumDeviceData.oSBuild()
        result[TealiumDeviceDataKey.cpuType] = TealiumDeviceData.cpuType()
        result.merge(TealiumDeviceData.model()) { (_, new) -> Any in
            new
        }
        result[TealiumDeviceDataKey.osVersion] = TealiumDeviceData.oSVersion()
        result[TealiumDeviceDataKey.osName] = TealiumDeviceData.oSName()
        result[TealiumDeviceDataKey.resolution] = TealiumDeviceData.resolution()
        return result
    }
    
    
    /// Data that needs to be polled at time of interest, these may change during the lifetime of the host app.
    ///
    /// - Returns: Dictionary of device data.
    func trackTimeData() -> [String : Any] {
        
        var result = [String:Any]()
        
        result[TealiumDeviceDataKey.batteryPercent] = TealiumDeviceData.batteryPercent()
        result[TealiumDeviceDataKey.isCharging] = TealiumDeviceData.isCharging()
        result[TealiumDeviceDataKey.language] = TealiumDeviceData.iso639Language()
        if isMemoryEnabled == true {
            result.merge(TealiumDeviceData.getMemoryUsage()) { (_, new) -> Any in
                new
            }
        }
        result.merge(TealiumDeviceData.orientation()) { (_, new) -> Any in
            new
        }
        result.merge(TealiumDeviceData.carrierInfo()) { (_, new) -> Any in
            new
        }
        return result
        
    }
}

enum TealiumDeviceDataKey {
    static let simpleModel = "model_name" // e.g. iPhone 5s
    static let fullModel = "model_variant" // e.g. CDMA, GSM
    static let architecture = "cpu_architecture"
    static let batteryPercent = "battery_percent"
    static let cpuType = "cpu_type"
    static let isCharging = "device_is_charging"
    static let language = "user_locale"
    static let appMemoryUsage = "app_memory_usage"
    static let memoryFree = "memory_free"
    static let memoryActive = "memory_active"
    static let memoryInactive = "memory_inactive"
    static let memoryCompressed = "memory_compressed"
    static let memoryWired = "memory_wired"
    static let physicalMemory = "memory_physical"
    static let orientation = "device_orientation"
    static let fullOrientation = "device_orientation_extended"
    static let osBuild = "os_build"
    static let osVersion = "os_version"
    static let osName = "os_name"
    static let resolution = "device_resolution"
    static let carrier = "network_name"
    static let carrierMNC = "network_mnc"
    static let carrierMCC = "network_mcc"
    static let carrierISO = "network_iso_country_code"
    static let connectionType = "network_connection_type"
}

class TealiumDeviceData {
    
    enum Unit : Double {
        // For going from byte to -
        case byte     = 1
        case kilobyte = 1024
        case megabyte = 1048576
        case gigabyte = 1073741824
    }
    
    class func architecture() -> String {
    
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
        
    }
    
    class func batteryPercent() -> String {
        // only available on iOS
        #if os(iOS)
            UIDevice.current.isBatteryMonitoringEnabled = true
            return String(describing: (UIDevice.current.batteryLevel * 100))
        #else
            return TealiumDeviceDataValue.unknown
        #endif
    }
    
    class func cpuType() -> String {
        
        var type = cpu_type_t()
        var cpuSize = MemoryLayout<cpu_type_t>.size
        sysctlbyname("hw.cputype", &type, &cpuSize, nil, 0)
        
        var subType = cpu_subtype_t()
        var subTypeSize = MemoryLayout<cpu_subtype_t>.size
        sysctlbyname("hw.cpusubtype", &subType, &subTypeSize, nil, 0)

        if type == CPU_TYPE_X86 {
            return "x86"
        }
        
        if subType == CPU_SUBTYPE_ARM64_V8 { return "ARM64v8"}
        if subType == CPU_SUBTYPE_ARM64_ALL { return "ARM64" }
        if subType == CPU_SUBTYPE_ARM_V8 { return "ARMV8"}
        if subType == CPU_SUBTYPE_ARM_V7 { return "ARMV7"}
        if subType == CPU_SUBTYPE_ARM_V7EM { return "ARMV7em"}
        if subType == CPU_SUBTYPE_ARM_V7F { return "ARMV7f"}
        if subType == CPU_SUBTYPE_ARM_V7K { return "ARMV7k"}
        if subType == CPU_SUBTYPE_ARM_V7M { return "ARMV7m"}
        if subType == CPU_SUBTYPE_ARM_V7S { return "ARMV7s"}
        if subType == CPU_SUBTYPE_ARM_V6 { return "ARMV6"}
        if subType == CPU_SUBTYPE_ARM_V6M { return "ARMV6m"}

        if type == CPU_TYPE_ARM { return "ARM" }

        
        return TealiumDeviceDataValue.unknown
    }
    
    class func isCharging() -> String {
        // only available on iOS
        #if os(iOS)
            if UIDevice.current.batteryState == .charging {
                return "true"
            }
            
            return "false"
        #else
            return TealiumDeviceDataValue.unknown
        #endif
    }
    
    class func iso639Language() -> String {
        
        return Locale.preferredLanguages[0]
        
    }
    
    // enabled/disabled via config object (default disabled)
    class func getMemoryUsage() -> [String: String] {
            
            // total physical memory in megabytes
            let physical = Double(ProcessInfo.processInfo.physicalMemory) / Unit.megabyte.rawValue
            
            // current memory used by this process/app
            var info = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            var appMemoryUsed = ""
            
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_,
                              task_flavor_t(MACH_TASK_BASIC_INFO),
                              $0,
                              &count)
                }
            }
        
            if kerr == KERN_SUCCESS {
                // appMemoryUsed = String("\(info.resident_size/Unit.megabyte.rawValue)MB")
                appMemoryUsed = String(format: "%0.2fMB", Double(info.resident_size) / Unit.megabyte.rawValue)
            } else {
                appMemoryUsed = TealiumDeviceDataValue.unknown
            }
            
            // summary of used system memory
            let PAGE_SIZE = vm_kernel_page_size
            let machHost = mach_host_self()
            var size     = HOST_VM_INFO64_COUNT
            let hostInfo = vm_statistics64_t.allocate(capacity: 1)
            
            let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(machHost,
                                  HOST_VM_INFO64,
                                  $0,
                                  &size)
            }
            
            let data = hostInfo.move()
            hostInfo.deallocate(capacity: 1)
            
            let free     = Double(data.free_count) * Double(PAGE_SIZE)
                / Unit.megabyte.rawValue
            let active   = Double(data.active_count) * Double(PAGE_SIZE)
                / Unit.megabyte.rawValue
            let inactive = Double(data.inactive_count) * Double(PAGE_SIZE)
                / Unit.megabyte.rawValue
            let wired    = Double(data.wire_count) * Double(PAGE_SIZE)
                / Unit.megabyte.rawValue
            // Result of the compression. This is what you see in Activity Monitor
            let compressed = Double(data.compressor_page_count) * Double(PAGE_SIZE)
                / Unit.megabyte.rawValue
            
            let dict = [
            
                TealiumDeviceDataKey.memoryFree: String(format: "%0.2fMB", free),
                TealiumDeviceDataKey.memoryInactive: String(format: "%0.2fMB", inactive),
                TealiumDeviceDataKey.memoryWired : String(format: "%0.2fMB", wired),
                TealiumDeviceDataKey.memoryActive: String(format: "%0.2fMB", active),
                TealiumDeviceDataKey.memoryCompressed: String(format: "%0.2fMB", compressed),
                TealiumDeviceDataKey.physicalMemory: String(format: "%0.2fMB", physical),
                TealiumDeviceDataKey.appMemoryUsage: appMemoryUsed
            ]
            
            return dict
    }
    
    class func model() -> [String:String] {
        var model = ""
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
                model = simulatorModelIdentifier
        }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        model = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        
        switch model {
            // iPhone
            case "iPhone4,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 4S", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone5,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5", TealiumDeviceDataKey.fullModel: "model A1428, AT&T/Canada"]
            case "iPhone5,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5", TealiumDeviceDataKey.fullModel: "(model A1429, except AT&T/Canada)"]
            case "iPhone5,3":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5c", TealiumDeviceDataKey.fullModel: "(model A1456, A1532 | GSM)"]
            case "iPhone5,4":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5c", TealiumDeviceDataKey.fullModel: "(model A1507, A1516, A1526 (China), A1529 | Global)"]
            case "iPhone6,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5s", TealiumDeviceDataKey.fullModel: "(model A1433, A1533 | GSM)"]
            case "iPhone6,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 5s", TealiumDeviceDataKey.fullModel: "(model A1457, A1518, A1528 (China), A1530 | Global)"]
            case "iPhone7,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 6 Plus", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone7,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 6", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone8,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 6S", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone8,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 6S Plus", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone8,4":
                return [TealiumDeviceDataKey.simpleModel: "iPhone SE", TealiumDeviceDataKey.fullModel: ""]
            case "iPhone9,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 7", TealiumDeviceDataKey.fullModel: "CDMA"]
            case "iPhone9,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 7 Plus", TealiumDeviceDataKey.fullModel: "CDMA"]
            case "iPhone9,3":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 7", TealiumDeviceDataKey.fullModel: "GSM"]
            case "iPhone9,4":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 7 Plus", TealiumDeviceDataKey.fullModel: "GSM"]
            case "iPhone10,1":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 8", TealiumDeviceDataKey.fullModel: "CDMA"]
            case "iPhone10,2":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 8 Plus", TealiumDeviceDataKey.fullModel: "CDMA"]
            case "iPhone10,3":
                return [TealiumDeviceDataKey.simpleModel: "iPhone X", TealiumDeviceDataKey.fullModel: "CDMA"]
            case "iPhone10,4":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 8", TealiumDeviceDataKey.fullModel: "GSM"]
            case "iPhone10,5":
                return [TealiumDeviceDataKey.simpleModel: "iPhone 8 Plus", TealiumDeviceDataKey.fullModel: "GSM"]
            case "iPhone10,6":
                return [TealiumDeviceDataKey.simpleModel: "iPhone X", TealiumDeviceDataKey.fullModel: "GSM"]
            // iPod Touch
            case "iPod5,1":
                return [TealiumDeviceDataKey.simpleModel: "iPod Touch 5th Generation", TealiumDeviceDataKey.fullModel: ""]
            case "iPod7,1":
                return [TealiumDeviceDataKey.simpleModel: "iPod Touch 6th Generation", TealiumDeviceDataKey.fullModel: ""]
            // iPad
            case "iPad2,1":
                return [TealiumDeviceDataKey.simpleModel: "iPad 2", TealiumDeviceDataKey.fullModel: "Wifi (model A1432)"]
            case "iPad2,2":
                return [TealiumDeviceDataKey.simpleModel: "iPad 2", TealiumDeviceDataKey.fullModel: "GSM (model A1396)"]
            case "iPad2,3":
                return [TealiumDeviceDataKey.simpleModel: "iPad 2", TealiumDeviceDataKey.fullModel: "3G (model A1397)"]
            case "iPad2,4":
                return [TealiumDeviceDataKey.simpleModel: "iPad 2", TealiumDeviceDataKey.fullModel: "Wifi (model A1395)"]
            case "iPad2,5":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini", TealiumDeviceDataKey.fullModel: "Wifi (model A1432)"]
            case "iPad2,6":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1454)"]
            case "iPad2,7":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1455)"]
            case "iPad3,1":
                return [TealiumDeviceDataKey.simpleModel: "iPad 3", TealiumDeviceDataKey.fullModel: "Wifi (model A1416)"]
            case "iPad3,2":
                return [TealiumDeviceDataKey.simpleModel: "iPad 3", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1403)"]
            case "iPad3,3":
                return [TealiumDeviceDataKey.simpleModel: "iPad 3", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1430)"]
            case "iPad3,4":
                return [TealiumDeviceDataKey.simpleModel: "iPad 4", TealiumDeviceDataKey.fullModel: "Wifi (model A1458)"]
            case "iPad3,5":
                return [TealiumDeviceDataKey.simpleModel: "iPad 4", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1459)"]
            case "iPad3,6":
                return [TealiumDeviceDataKey.simpleModel: "iPad 4", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model  A1460)"]
            case "iPad4,1":
                return [TealiumDeviceDataKey.simpleModel: "iPad Air", TealiumDeviceDataKey.fullModel: "Wifi (model A1474)"]
            case "iPad4,2":
                return [TealiumDeviceDataKey.simpleModel: "iPad Air", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1475)"]
            case "iPad4,3":
                return [TealiumDeviceDataKey.simpleModel: "iPad Air", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1476)"]
            case "iPad4,4":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 2", TealiumDeviceDataKey.fullModel: "Wifi (model A1489)"]
            case "iPad4,5":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 2", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1490)"]
            case "iPad4,6":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 2", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1491)"]
            case "iPad4,7":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 3", TealiumDeviceDataKey.fullModel: "Wifi (model A1599)"]
            case "iPad4,8":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 3", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1600)"]
            case "iPad4,9":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 3", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1601)"]
            case "iPad5,1":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 4", TealiumDeviceDataKey.fullModel: "Wifi (model A1538)"]
            case "iPad5,2":
                return [TealiumDeviceDataKey.simpleModel: "iPad Mini 4", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1550)"]
            case "iPad5,3":
                return [TealiumDeviceDataKey.simpleModel: "iPad Air 2", TealiumDeviceDataKey.fullModel: "Wifi (model A1566)"]
            case "iPad5,4":
                return [TealiumDeviceDataKey.simpleModel: "iPad Air 2", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1567)"]
            case "iPad6,3":
                return [TealiumDeviceDataKey.simpleModel: "iPad Pro 12.9\"", TealiumDeviceDataKey.fullModel: "Wifi (model A1673)"]
            case "iPad6,4":
                return [TealiumDeviceDataKey.simpleModel: "iPad Pro 12.9\"", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1674, A1675)"]
            case "iPad6,7":
                return [TealiumDeviceDataKey.simpleModel: "iPad Pro 9.7\"", TealiumDeviceDataKey.fullModel: "Wifi (model A1584)"]
            case "iPad6,8":
                return [TealiumDeviceDataKey.simpleModel: "iPad Pro 9.7\"", TealiumDeviceDataKey.fullModel: "Wifi + Cellular (model A1652)"]
            // Apple TV
            case "AppleTV2,1":
                return [TealiumDeviceDataKey.simpleModel: "Apple TV 2nd Generation", TealiumDeviceDataKey.fullModel: ""]
            case "AppleTV3,1":
                return [TealiumDeviceDataKey.simpleModel: "Apple TV 3rd Generation", TealiumDeviceDataKey.fullModel: ""]
            case "AppleTV3,2":
                return [TealiumDeviceDataKey.simpleModel: "Apple TV 3rd Generation", TealiumDeviceDataKey.fullModel: ""]
            case "AppleTV5,3":
                return [TealiumDeviceDataKey.simpleModel: "Apple TV 4th Generation", TealiumDeviceDataKey.fullModel: ""]
            case "AppleTV6,2":
                return [TealiumDeviceDataKey.simpleModel: "Apple TV 4K", TealiumDeviceDataKey.fullModel: ""]
            // Apple Watch
            case "Watch1,1":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch 1st Generation", TealiumDeviceDataKey.fullModel: "38mm"]
            case "Watch1,2":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch 1st Generation", TealiumDeviceDataKey.fullModel: "42mm"]
            case "Watch2,3":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 2", TealiumDeviceDataKey.fullModel: "38mm"]
            case "Watch2,4":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 2", TealiumDeviceDataKey.fullModel: "42mm"]
            case "Watch2,6":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 1", TealiumDeviceDataKey.fullModel: "38mm"]
            case "Watch2,7":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 1", TealiumDeviceDataKey.fullModel: "42mm"]
            case "Watch3,1":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 3", TealiumDeviceDataKey.fullModel: "38mm Cellular"]
            case "Watch3,2":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 3", TealiumDeviceDataKey.fullModel: "42mm Cellular"]
            // GPS only - no cellular:
            case "Watch3,3":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 3", TealiumDeviceDataKey.fullModel: "38mm"]
            case "Watch3,4":
                return [TealiumDeviceDataKey.simpleModel: "Apple Watch Series 3", TealiumDeviceDataKey.fullModel: "42mm"]
            // unknown:
            default:
                return [TealiumDeviceDataKey.simpleModel: model, TealiumDeviceDataKey.fullModel: ""]
        }
    }
    
    class func name() -> String {
        #if os(OSX)
            return TealiumDeviceDataValue.unknown
        #elseif os(watchOS)
            return TealiumDeviceDataValue.appleWatch
        #else
            return UIDevice.current.model
        #endif
    }
    
    class func carrierInfo() -> Dictionary<String, String> {
        #if os(watchOS)
            return [
                TealiumDeviceDataKey.connectionType : TealiumDeviceDataValue.unknown
            ]
        #else
        let thisClassName = String(reflecting: self)
        // NOTE: dependency on Connectivity module here. Checking if loaded before calling
        let cls = objc_getClass(thisClassName)
        var connection = "not available"
        if cls != nil {
            connection = TealiumConnectivityModule.currentConnectionType()
        }
        // only available on iOS
        #if os(iOS)
            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.subscriberCellularProvider
            return [
                TealiumDeviceDataKey.carrierMNC : carrier?.mobileNetworkCode ?? "",
                TealiumDeviceDataKey.carrierMCC : carrier?.mobileCountryCode ?? "",
                TealiumDeviceDataKey.carrierISO : carrier?.isoCountryCode ?? "",
                TealiumDeviceDataKey.carrier : carrier?.carrierName ?? "",
                TealiumDeviceDataKey.connectionType : connection
            ]
        #else
            return [
                TealiumDeviceDataKey.connectionType : connection
            ]
        #endif
        #endif
    }
    
    class func resolution() -> String {
        #if os(OSX)
            return TealiumDeviceDataValue.unknown
        #elseif os(watchOS)
            let res = WKInterfaceDevice.current().screenBounds
            let scale = WKInterfaceDevice.current().screenScale
            let width = res.width * scale
            let height = res.height * scale
            let stringRes = String(format: "%.0fx%.0f", height, width)
            return stringRes
        #else
            let res = UIScreen.main.bounds
            let scale = UIScreen.main.scale
            let width = res.width * scale
            let height = res.height * scale
            let stringRes = String(format: "%.0fx%.0f", height, width)
            return stringRes
        #endif
    }
    
    class func orientation() -> Dictionary<String, String> {
        // UIDevice.current.orientation is available on iOS only
        #if os(iOS)
            let orientation = UIDevice.current.orientation
            
            let isLandscape = orientation.isLandscape
            var fullOrientation = [TealiumDeviceDataKey.orientation : isLandscape ? "Landscape" : "Portrait"]
            
            switch orientation {
                case .faceUp:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Face Up"
                case .faceDown:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Face Down"
                case .landscapeLeft:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Landscape Left"
                case .landscapeRight:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Landscape Right"
                case .portrait:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Portrait"
                case .portraitUpsideDown:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = "Portrait Upside Down"
                case .unknown:
                    fullOrientation[TealiumDeviceDataKey.fullOrientation] = TealiumDeviceDataValue.unknown
            }
            return fullOrientation
        #else
            return [TealiumDeviceDataKey.orientation : TealiumDeviceDataValue.unknown, TealiumDeviceDataKey.fullOrientation: TealiumDeviceDataValue.unknown]
        #endif
    }
    
    class func oSBuild() -> String {
        
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return TealiumDeviceDataValue.unknown
        }
        return build
        
    }
    
    class func oSVersion() -> String {
        // only available on iOS and tvOS
        #if os(iOS)
            return UIDevice.current.systemVersion
        #elseif os(tvOS)
            return UIDevice.current.systemVersion
        #elseif os(watchOS)
            return WKInterfaceDevice.current().systemVersion
        #elseif os(OSX)
            return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return TealiumDeviceDataValue.unknown
        #endif
    }
    
    class func oSName() -> String {
        // only available on iOS and tvOS
        #if os(iOS)
            return UIDevice.current.systemName
        #elseif os(tvOS)
            return UIDevice.current.systemName
        #elseif os(OSX)
            return "macOS"
        #else
            return TealiumDeviceDataValue.unknown
        #endif
    }
    
}

extension TealiumConfig {
    
    public func isMemoryReportingEnabled() -> Bool {
        
        if let enabled = self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] as? Bool {
            return enabled
        }
        
        // Default
        return false
        
    }
    
    public func setMemoryReportingEnabled(_ enabled: Bool) {
        self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] = enabled
    }
    
}
