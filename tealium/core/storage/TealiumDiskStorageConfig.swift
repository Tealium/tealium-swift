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
        options[TealiumKey.minimumFreeDiskSpace] = spaceInMB * 1_000_000
    }

    /// - Returns: `Int` containing the minimum free space in Megabytes allowed for Disk Storage to be enabled
    func getMinimumFreeDiskSpace() -> Int32? {
        minimumFreeDiskSpace
    }

    /// Sets the minimum free disk space in Megabytes  for Disk Storage to be enabled
    var minimumFreeDiskSpace: Int32? {
        get {
            options[TealiumKey.minimumFreeDiskSpace] as? Int32
        }

        set {
            guard let newValue = newValue else {
                options[TealiumKey.minimumFreeDiskSpace] = nil
                return
            }
            options[TealiumKey.minimumFreeDiskSpace] = newValue * 1_000_000
        }
    }

    /// Enables (default) or disables disk storage.
    /// If disabled, only critical data will be saved, and UserDefaults will be used in place of disk storage￼.
    var diskStorageEnabled: Bool {
        get {
            options[TealiumKey.diskStorageEnabled] as? Bool ?? true
        }

        set {
            options[TealiumKey.diskStorageEnabled] = newValue
        }
    }

    /// Sets the directory to be used for disk storage. Default `.caches`.
    var diskStorageDirectory: Disk.Directory? {
        get {
            options[TealiumKey.diskStorageDirectory] as? Disk.Directory
        }

        set {
            options[TealiumKey.diskStorageDirectory] = newValue
        }
    }

}
