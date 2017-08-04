//
//  TealiumDeviceDataModule.swift
//  SegueCatalog
//
//  Created by Jason Koo on 8/3/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import UIKit

enum TealiumDeviceDataModuleKey {
    static let moduleName = "devicedata"
}

enum TealiumDeviceDataValue {
    static let unknown = "unknown"
}

class TealiumDeviceDataModule : TealiumModule {
    
    var data = [String:Any]()
    
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumDeviceDataModuleKey.moduleName,
                                   priority: 525,
                                   build: 1,
                                   enabled: true)
    }
    
    override func enable(_ request: TealiumEnableRequest) {
        
        isEnabled = true
        data = enableTimeData()
        
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
        result[TealiumDeviceDataKey.build] = TealiumDeviceData.oSBuild()
        result[TealiumDeviceDataKey.cpuType] = TealiumDeviceData.cpuType()
        result[TealiumDeviceDataKey.model] = TealiumDeviceData.model()
        result[TealiumDeviceDataKey.name] = TealiumDeviceData.name()
        result[TealiumDeviceDataKey.osVersion] = TealiumDeviceData.oSVersion()

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
        result[TealiumDeviceDataKey.orientation] = TealiumDeviceData.orientation()

        return result
        
    }
}

enum TealiumDeviceDataKey {
    static let name = "device"
    static let architecture = "device_architecture"
    static let batteryPercent = "device_battery_percent"
    static let build = "device_build"
    static let cpuType = "device_cputype"
    static let isCharging = "device_ischarging"
    static let language = "device_language"
    static let memoryAvailable = "device_memory_available"
    static let memoryUsage = "device_memory_usage"
    static let model = "device_model"
    static let orientation = "device_orientation"
    static let osBuild = "device_os_build"
    static let osVersion = "device_os_version"
    static let resolution = "device_resolution"
}

class TealiumDeviceData {
    
    class func architecture() -> String {
    
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
        
    }
    
    class func batteryPercent() -> String {
    
        return String(describing: (UIDevice.current.batteryLevel * 100))
        
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
        
        if type == CPU_TYPE_ARM {
            if subType == CPU_SUBTYPE_ARM64_V8 { return "ARM64v8"}
            if subType == CPU_SUBTYPE_ARM64_ALL { return "ARM64" }
            if subType == CPU_SUBTYPE_ARM_V8 { return "ARMV8"}
            if subType == CPU_SUBTYPE_ARM_V7 { return "ARMV7"}
            if subType == CPU_SUBTYPE_ARM_V7EM { return "ARMV7em"}
            if subType == CPU_SUBTYPE_ARM_V7F { return "ARMV7f"}
            if subType == CPU_SUBTYPE_ARM_V7K { return "ARMV7k"}
            if subType == CPU_SUBTYPE_ARM_V7M { return "ARMV7m"}
            if subType == CPU_SUBTYPE_ARM_V7S { return "ARMV7s"}
            if subType == CPU_SUBTYPE_ARM_V6 { return "ARMV6" }
            if subType == CPU_SUBTYPE_ARM_V6M { return "ARMV6m" }

        }
        
        return "Unknown"
    }
    
    class func isCharging() -> String {
    
        if UIDevice.current.batteryState == .charging {
            return "true"
        }
        
        return "false"
    }
    
    class func iso639Language() -> String {
        
        return Locale.preferredLanguages[0]
        
    }
    
    class func memoryAvailable() -> String {
        
        // TODO:
        return ""
    }
    
    class func memoryUsage() -> String {
        
        // TODO:
        return ""
    }
    
    class func model() -> String {
        
        
        // TODO:
        return ""
    }
    
    class func name() -> String {
        
        return UIDevice.current.model
    }
    
    class func orientation() -> String {
        
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .faceUp:
            return "Face Up"
        case .faceDown:
            return "Face Down"
        case .landscapeLeft:
            return "Landscape Left"
        case .landscapeRight:
            return "Landscape Right"
        case .portrait:
            return "Portrait"
        case .portraitUpsideDown:
            return "Portrait"
        case .unknown:
            return TealiumDeviceDataValue.unknown
        }
        
    }
    
    class func oSBuild() -> String {
        
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return TealiumDeviceDataValue.unknown
        }
        return build
        
    }
    
    class func oSVersion() -> String {
        
        return UIDevice.current.systemVersion
    }
    
}
