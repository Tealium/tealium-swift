//
//  TealiumDiskStorageConfig.swift
//  tealium-swift
//
//  Created by Craig Rouse on 28/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumConfig {

    /// Sets the minimum free disk space on the device for Disk Storage to be enabled
    ///
    /// - Parameter spaceInMB: `Int` containing the minimum amount for free space in Megabytes (default 20MB)
    func setMinimumFreeDiskSpace(spaceInMB: Int32) {
        optionalData[TealiumKey.minimumFreeDiskSpace] = spaceInMB * 1_000_000
    }

    /// - Returns: `Int` containing the minimum free space in Megabytes allowed for Disk Storage to be enabled
    func getMinimumFreeDiskSpace() -> Int32 {
        return optionalData[TealiumKey.minimumFreeDiskSpace] as? Int32 ?? TealiumValue.defaultMinimumDiskSpace
    }

    /// Enables (default) or disables disk storage.
    /// If disabled, only critical data will be saved, and UserDefaults will be used in place of disk storage￼.
    ///
    /// - Parameter isEnabled: `Bool` indicating if disk storage should be enabled (default) or disabled
    func setDiskStorageEnabled(isEnabled: Bool = true) {
        self.optionalData[TealiumKey.diskStorageEnabled] = isEnabled
    }

    /// Checks whether Disk Storage is currently enabled
    ///￼
    /// - Returns:`Bool` indicating if disk storage is enabled (default) or disabled
    func isDiskStorageEnabled() -> Bool {
        return self.optionalData[TealiumKey.diskStorageEnabled] as? Bool ?? true
    }
    
    func setOverrideDiskStorageDirectory(_ directory: Disk.Directory) {
        self.optionalData[TealiumKey.diskStorageDirectory] = directory
    }
    
    func getOverrideDiskStorageDirectory() -> Disk.Directory? {
        return self.optionalData[TealiumKey.diskStorageDirectory] as? Disk.Directory ?? nil
    }

}
