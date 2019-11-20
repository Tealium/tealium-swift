//
//  TealiumDeviceDataCollection.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumDeviceDataCollection {
    func getMemoryUsage() -> [String: String]

    func orientation() -> [String: String]

    func model() -> [String: String]

    func basicModel() -> String

    func cpuType() -> String
}

public extension TealiumDeviceDataCollection {
    /// - Returns: `String` containing the device's CPU architecture
    func architecture() -> String {
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
    }
}
