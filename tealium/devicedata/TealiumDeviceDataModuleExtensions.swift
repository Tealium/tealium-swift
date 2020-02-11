//
//  TealiumDeviceDataExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if devicedata
import TealiumCore
#endif

public extension TealiumConfig {

    /// Determines whether memory reporting is currently enabled.
    /// 
    /// - Returns: `Bool` `true` if enabled, else `false` (default)
    @available(*, deprecated, message: "Please switch to config.memoryReportingEnabled")
    func isMemoryReportingEnabled() -> Bool {
        memoryReportingEnabled
    }

    /// Enables or disables memory reporting￼.
    ///
    /// - Parameter `Bool` `true` to enable (default disabled)
    @available(*, deprecated, message: "Please switch to config.memoryReportingEnabled")
    func setMemoryReportingEnabled(_ enabled: Bool) {
        memoryReportingEnabled = enabled
    }

    var memoryReportingEnabled: Bool {
        get {
            return optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] as? Bool ?? false
        }

        set {
            optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] = newValue
        }
    }

}
