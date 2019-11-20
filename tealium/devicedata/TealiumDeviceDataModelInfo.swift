//
//  TealiumDeviceDataModelInfo.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if devicedata
import TealiumCore
#endif

extension TealiumDeviceData {

    /// Retrieves the Apple model name, e.g. iPhone11,2.
    ///
    /// - Returns: `String` containing Apple model name
    public func basicModel() -> String {
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

    /// Retrieves device name mapping from JSON file in app bundle.
    ///
    /// - Returns: `[String: Any]` containing the model name information
    func retrieveModelNamesFromJSONFile() -> [String: Any]? {
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

    /// Retrieves the full consumer device name, e.g. iPhone SE, and other supplementary info.
    /// 
    /// - Returns: `[String: String]` of model information
    public func model() -> [String: String] {
        let model = basicModel()
        if let deviceInfo = retrieveModelNamesFromJSONFile() {
            if let currentModel = deviceInfo[model] as? [String: String],
                let simpleModel = currentModel[TealiumKey.simpleModel],
                let fullModel = currentModel[TealiumKey.fullModel] {
                return [TealiumKey.deviceType: model,
                        TealiumKey.simpleModel: simpleModel,
                        TealiumKey.device: simpleModel,
                        TealiumKey.fullModel: fullModel,
                ]
            }
        }
        return [TealiumKey.deviceType: model,
                TealiumKey.simpleModel: model,
                TealiumKey.fullModel: "",
        ]
    }
}
