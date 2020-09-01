//
//  DeviceDataExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    /// If enabled, this will add current memory reporting variables to the data layer
    /// Default is `false`
    var memoryReportingEnabled: Bool {
        get {
            return options[DeviceDataModuleKey.isMemoryReportingEnabled] as? Bool ?? false
        }

        set {
            options[DeviceDataModuleKey.isMemoryReportingEnabled] = newValue
        }
    }

}

public extension Collectors {
    static let Device = DeviceDataModule.self
}
