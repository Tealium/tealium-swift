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
    func isMemoryReportingEnabled() -> Bool {
        if let enabled = self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] as? Bool {
            return enabled
        }

        // Default
        return false
    }

    /// Enables or disables memory reporting￼.
    ///
    /// - Parameter `Bool` `true` to enable (default disabled)
    func setMemoryReportingEnabled(_ enabled: Bool) {
        self.optionalData[TealiumDeviceDataModuleKey.isMemoryReportingEnabled] = enabled
    }

}
