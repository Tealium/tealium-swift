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
        return [TealiumKey.deviceType: model,
                TealiumKey.simpleModel: "mac",
                TealiumKey.device: "mac",
                TealiumKey.fullModel: "mac"
        ]
        #else
        if let deviceInfo = allModelNames {
            if let currentModel = deviceInfo[model] as? [String: String],
               let simpleModel = currentModel[TealiumKey.simpleModel],
               let fullModel = currentModel[TealiumKey.fullModel] {
                return [TealiumKey.deviceType: model,
                        TealiumKey.simpleModel: simpleModel,
                        TealiumKey.device: simpleModel,
                        TealiumKey.fullModel: fullModel
                ]
            }
        }

        return [TealiumKey.deviceType: model,
                TealiumKey.simpleModel: model,
                TealiumKey.device: model,
                TealiumKey.fullModel: ""
        ]
        #endif
    }
}
