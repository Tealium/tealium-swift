//
//  TealiumDeviceData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif
import Foundation

#if os(tvOS)
#elseif os(watchOS)
#else
import CoreTelephony
#endif
#if os(watchOS)
import WatchKit
#endif

#if devicedata
import TealiumCore
#endif

import Darwin

public protocol TealiumDeviceDataCollection {
    func getMemoryUsage() -> [String: String]

    func orientation() -> [String: String]

    func model() -> [String: String]

    func basicModel() -> String

    func cpuType() -> String
}

public extension TealiumDeviceDataCollection {
    func architecture() -> String {
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
    }
}

// swiftlint:disable identifier_name
private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t =
    UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

// swiftlint:enable identifier_name
// swiftlint:disable file_length
// swiftlint:disable type_body_length
public class TealiumDeviceData: TealiumDeviceDataCollection {

    #if os(iOS)
    private class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    public init() {
    }

    enum Unit: Double {
        // For going from byte to -
        case byte = 1
        case kilobyte = 1024
        case megabyte = 1048576
        case gigabyte = 1073741824
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

    // swiftlint:disable cyclomatic_complexity
    public func cpuType() -> String {
        var type = cpu_type_t()
        var cpuSize = MemoryLayout<cpu_type_t>.size
        sysctlbyname("hw.cputype", &type, &cpuSize, nil, 0)

        var subType = cpu_subtype_t()
        var subTypeSize = MemoryLayout<cpu_subtype_t>.size
        sysctlbyname("hw.cpusubtype", &subType, &subTypeSize, nil, 0)

        if type == CPU_TYPE_X86 {
            return "x86"
        }

        if subType == CPU_SUBTYPE_ARM64_V8 {
            return "ARM64v8"
        }
        if subType == CPU_SUBTYPE_ARM64_ALL {
            return "ARM64"
        }
        if subType == CPU_SUBTYPE_ARM_V8 {
            return "ARMV8"
        }
        if subType == CPU_SUBTYPE_ARM_V7 {
            return "ARMV7"
        }
        if subType == CPU_SUBTYPE_ARM_V7EM {
            return "ARMV7em"
        }
        if subType == CPU_SUBTYPE_ARM_V7F {
            return "ARMV7f"
        }
        if subType == CPU_SUBTYPE_ARM_V7K {
            return "ARMV7k"
        }
        if subType == CPU_SUBTYPE_ARM_V7M {
            return "ARMV7m"
        }
        if subType == CPU_SUBTYPE_ARM_V7S {
            return "ARMV7s"
        }
        if subType == CPU_SUBTYPE_ARM_V6 {
            return "ARMV6"
        }
        if subType == CPU_SUBTYPE_ARM_V6M {
            return "ARMV6m"
        }

        if type == CPU_TYPE_ARM {
            return "ARM"
        }

        return TealiumDeviceDataValue.unknown
    }

    // swiftlint:enable cyclomatic_complexity

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
    // swiftlint:disable function_body_length
    public func getMemoryUsage() -> [String: String] {
        // total physical memory in megabytes
        let physical = Double(ProcessInfo.processInfo.physicalMemory) / Unit.megabyte.rawValue

        // current memory used by this process/app
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
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
        let pageSize = vm_kernel_page_size
        let machHost = mach_host_self()
        var size = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost,
                              HOST_VM_INFO64,
                              $0,
                              &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()

        let free = Double(data.free_count) * Double(pageSize)
            / Unit.megabyte.rawValue
        let active = Double(data.active_count) * Double(pageSize)
            / Unit.megabyte.rawValue
        let inactive = Double(data.inactive_count) * Double(pageSize)
            / Unit.megabyte.rawValue
        let wired = Double(data.wire_count) * Double(pageSize)
            / Unit.megabyte.rawValue
        // Result of the compression. This is what you see in Activity Monitor
        let compressed = Double(data.compressor_page_count) * Double(pageSize)
            / Unit.megabyte.rawValue

        let dict = [
            TealiumDeviceDataKey.memoryFree: String(format: "%0.2fMB", free),
            TealiumDeviceDataKey.memoryInactive: String(format: "%0.2fMB", inactive),
            TealiumDeviceDataKey.memoryWired: String(format: "%0.2fMB", wired),
            TealiumDeviceDataKey.memoryActive: String(format: "%0.2fMB", active),
            TealiumDeviceDataKey.memoryCompressed: String(format: "%0.2fMB", compressed),
            TealiumDeviceDataKey.physicalMemory: String(format: "%0.2fMB", physical),
            TealiumDeviceDataKey.appMemoryUsage: appMemoryUsed,
        ]

        return dict
    }
    // swiftlint:enable function_body_length

    public func basicModel() -> String {
        var model = ""
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            model = simulatorModelIdentifier
        }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        model = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)

        return model
    }

    func getJSONData() -> [String: Any]? {
        let bundle = Bundle(for: type(of: self))

        guard let path = bundle.path(forResource: TealiumDeviceDataKey.fileName, ofType: "json") else {
            return nil
        }
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            if let result = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: String]] {
                return result
            }
        }
        return nil
    }

    public func model() -> [String: String] {
        let model = basicModel()
        if let deviceInfo = self.getJSONData() {
            if let currentModel = deviceInfo[model] as? [String: String],
                let simpleModel = currentModel[TealiumDeviceDataKey.simpleModel],
                let fullModel = currentModel[TealiumDeviceDataKey.fullModel] {
                return [TealiumDeviceDataKey.simpleModel: simpleModel,
                        TealiumDeviceDataKey.device: simpleModel,
                        TealiumDeviceDataKey.fullModel: fullModel,
                ]
            }
        }
        return [TealiumDeviceDataKey.simpleModel: model,
                TealiumDeviceDataKey.fullModel: "",
        ]
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

    class func carrierInfo() -> [String: String] {
        // only available on iOS
        var carrierInfo = [String: String]()
        #if os(iOS)
        // beginning in iOS 12, Xcode generates lots errors
        // when calling CTTelephonyNetworkInfo from the simulator
        // this is a workaround
        #if targetEnvironment(simulator)
        carrierInfo = [
            TealiumDeviceDataKey.carrierMNC: "00",
            TealiumDeviceDataKey.carrierMCC: "000",
            TealiumDeviceDataKey.carrierISO: "us",
            TealiumDeviceDataKey.carrier: "simulator",
            TealiumDeviceDataKey.carrierMNCLegacy: "00",
            TealiumDeviceDataKey.carrierMCCLegacy: "000",
            TealiumDeviceDataKey.carrierISOLegacy: "us",
            TealiumDeviceDataKey.carrierLegacy: "simulator",
        ]
        #else
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        if #available(iOS 12.0, *) {
            if let newCarrier = networkInfo.serviceSubscriberCellularProviders {
                // pick up the first carrier in the list
                for currentCarrier in newCarrier {
                    carrier = currentCarrier.value
                    break
                }
            }
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        carrierInfo = [
            TealiumDeviceDataKey.carrierMNCLegacy: carrier?.mobileNetworkCode ?? "",
            TealiumDeviceDataKey.carrierMNC: carrier?.mobileNetworkCode ?? "",
            TealiumDeviceDataKey.carrierMCCLegacy: carrier?.mobileCountryCode ?? "",
            TealiumDeviceDataKey.carrierMCC: carrier?.mobileCountryCode ?? "",
            TealiumDeviceDataKey.carrierISOLegacy: carrier?.isoCountryCode ?? "",
            TealiumDeviceDataKey.carrierISO: carrier?.isoCountryCode ?? "",
            TealiumDeviceDataKey.carrierLegacy: carrier?.carrierName ?? "",
            TealiumDeviceDataKey.carrier: carrier?.carrierName ?? "",
        ]
        #endif
        #endif
        return carrierInfo
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

    public func orientation() -> [String: String] {
        // UIDevice.current.orientation is available on iOS only
        #if os(iOS)
        let orientation = UIDevice.current.orientation
        var appOrientation: UIInterfaceOrientation?

        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                appOrientation = TealiumDeviceData.sharedApplication?.statusBarOrientation
            }
        } else {
            appOrientation = TealiumDeviceData.sharedApplication?.statusBarOrientation
        }

        let isLandscape = orientation.isLandscape
        var fullOrientation = [TealiumDeviceDataKey.orientation: isLandscape ? "Landscape" : "Portrait"]

        fullOrientation[TealiumDeviceDataKey.fullOrientation] = getDeviceOrientation(orientation)
        if let appOrientation = appOrientation {
            let isAppLandscape = appOrientation.isLandscape
            fullOrientation[TealiumDeviceDataKey.appOrientation] = isAppLandscape ? "Landscape" : "Portrait"
            fullOrientation[TealiumDeviceDataKey.appOrientationExtended] = getUIOrientation(appOrientation)
        }
        return fullOrientation
        #else
        return [TealiumDeviceDataKey.orientation: TealiumDeviceDataValue.unknown,
                TealiumDeviceDataKey.fullOrientation: TealiumDeviceDataValue.unknown,
        ]
        #endif
    }

    #if os(iOS)
    func getUIOrientation(_ orientation: UIInterfaceOrientation) -> String {
        var appOrientationString: String
        switch orientation {
        case .landscapeLeft:
            appOrientationString = "Landscape Left"
        case .landscapeRight:
            appOrientationString = "Landscape Right"
        case .portrait:
            appOrientationString = "Portrait"
        case .portraitUpsideDown:
            appOrientationString = "Portrait Upside Down"
        case .unknown:
            appOrientationString = TealiumDeviceDataValue.unknown
        }
        return appOrientationString
    }

    func getDeviceOrientation(_ orientation: UIDeviceOrientation) -> String {
        var deviceOrientationString: String
        switch orientation {
        case .faceUp:
            deviceOrientationString = "Face Up"
        case .faceDown:
            deviceOrientationString = "Face Down"
        case .landscapeLeft:
            deviceOrientationString = "Landscape Left"
        case .landscapeRight:
            deviceOrientationString = "Landscape Right"
        case .portrait:
            deviceOrientationString = "Portrait"
        case .portraitUpsideDown:
            deviceOrientationString = "Portrait Upside Down"
        case .unknown:
            deviceOrientationString = TealiumDeviceDataValue.unknown
        }
        return deviceOrientationString
    }
    #endif

    public class func oSBuild() -> String {
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return TealiumDeviceDataValue.unknown
        }
        return build

    }

    public class func oSVersion() -> String {
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

    public class func oSName() -> String {
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
// swiftlint:enable type_body_length
// swiftlint:enable file_length
