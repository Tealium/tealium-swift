//
//  TealiumDeviceData.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//
import Foundation

#if devicedata
import TealiumCore
#endif

#if os(OSX)
#else
import UIKit
#endif

public class TealiumDeviceData: TealiumDeviceDataCollection {

    #if os(iOS)
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    // needed for use by other modules
    public init() {
    }

    // MARK: Battery
    /// - Returns: `Int` battery percentage
    class func batteryPercent() -> String {
        // only available on iOS
        #if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        return String(describing: (UIDevice.current.batteryLevel * 100))
        #else
        return TealiumDeviceDataValue.unknown
        #endif
    }

    /// - Returns: `String` true if charging
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

    // MARK: CPU
    // swiftlint:disable cyclomatic_complexity
    /// - Returns: `String` containing current CPU type
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

        switch subType {
        case CPU_SUBTYPE_ARM64_V8:
            return "ARM64v8"
        case CPU_SUBTYPE_ARM64_ALL:
            return "ARM64"
        case CPU_SUBTYPE_ARM_V8:
            return "ARMV8"
        case CPU_SUBTYPE_ARM_V7:
            return "ARMV7"
        case CPU_SUBTYPE_ARM_V7EM:
            return "ARMV7em"
        case CPU_SUBTYPE_ARM_V7F:
            return "ARMV7f"
        case CPU_SUBTYPE_ARM_V7K:
            return "ARMV7k"
        case CPU_SUBTYPE_ARM_V7M:
            return "ARMV7m"
        case CPU_SUBTYPE_ARM_V7S:
            return "ARMV7s"
        case CPU_SUBTYPE_ARM_V6:
            return "ARMV6"
        case CPU_SUBTYPE_ARM_V6M:
            return "ARMV6m"
        case CPU_TYPE_ARM:
            return "ARM"
        default:
            return TealiumDeviceDataValue.unknown
        }
    }
    // swiftlint:enable cyclomatic_complexity

    /// - Returns: `String ` of  main locale of the device
    class func iso639Language() -> String {
        return Locale.preferredLanguages[0]
    }

}
