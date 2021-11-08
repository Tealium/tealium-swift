//
//  DeviceDataModelInfo.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension DeviceData {

    /// Retrieves the Apple model name, e.g. iPhone11,2.
    ///
    /// - Returns: `String` containing Apple model name
    var basicModel: String {
        if ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] != nil {
            return "x86_64"
        }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        guard let model = String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii) else {
            return ""
        }
        return model.trimmingCharacters(in: .controlCharacters)
    }

    /// Retrieves the full consumer device name, e.g. iPhone SE, and other supplementary info.
    ///
    /// - Returns: `[String: String]` of model information
    var model: [String: String] {
        let model = basicModel
        #if os(OSX)
        return [TealiumDataKey.deviceType: model,
                TealiumDataKey.simpleModel: "mac",
                TealiumDataKey.device: "mac",
                TealiumDataKey.fullModel: "mac"
        ]
        #else
        if let deviceInfo = allModelNames {
            if let currentModel = deviceInfo[model] as? [String: String],
               let simpleModel = currentModel[TealiumDataKey.simpleModel],
               let fullModel = currentModel[TealiumDataKey.fullModel] {
                return [TealiumDataKey.deviceType: model,
                        TealiumDataKey.simpleModel: simpleModel,
                        TealiumDataKey.device: simpleModel,
                        TealiumDataKey.fullModel: fullModel
                ]
            }
        }

        return [TealiumDataKey.deviceType: model,
                TealiumDataKey.simpleModel: model,
                TealiumDataKey.device: model,
                TealiumDataKey.fullModel: ""
        ]
        #endif
    }
}
