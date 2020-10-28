//
//  DeviceDataCollection.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DeviceDataCollection {
    var memoryUsage: [String: String] { get }

    var orientation: [String: String] { get }

    var model: [String: String] { get }

    var basicModel: String { get }

    var cpuType: String { get }
}

public extension DeviceDataCollection {
    /// - Returns: `String` containing the device's CPU architecture
    func architecture() -> String {
        let bit = MemoryLayout<Int>.size
        if bit == MemoryLayout<Int64>.size {
            return "64"
        }
        return "32"
    }
}
