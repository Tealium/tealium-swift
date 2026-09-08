//
//  DeviceDataMemoryInfo.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Darwin
import Foundation

// swiftlint:disable identifier_name
private let HOST_VM_INFO64_COUNT: mach_msg_type_number_t =
    UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
// swiftlint:enable identifier_name

public extension DeviceData {

    enum Unit: Int64 {
        // For going from byte to -
        case byte = 1
        case kilobyte = 1024
        case megabyte = 1_048_576
        case gigabyte = 1_073_741_824
    }

    // enabled/disabled via config object (default disabled)
    /// - Returns: `[String: Int]` containing current memory usage info, in whole megabytes
    var memoryUsage: [String: Int64] {
        // total physical memory in megabytes
        let physical = Int64(ProcessInfo.processInfo.physicalMemory) / Unit.megabyte.rawValue

        // current memory used by this process/app, in whole megabytes
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        var appMemoryUsed: Int64 = 0

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        if kerr == KERN_SUCCESS {
            appMemoryUsed = Int64(info.resident_size) / Unit.megabyte.rawValue
        }

        // summary of used system memory
        let pageSize = vm_kernel_page_size
        let machHost = mach_host_self()
        var size = HOST_VM_INFO64_COUNT
        let hostInfo = vm_statistics64_t.allocate(capacity: 1)

        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(machHost, HOST_VM_INFO64, $0, &size)
        }

        let data = hostInfo.move()
        hostInfo.deallocate()

        let free = Int64(data.free_count) * Int64(pageSize)
            / Unit.megabyte.rawValue
        let active = Int64(data.active_count) * Int64(pageSize)
            / Unit.megabyte.rawValue
        let inactive = Int64(data.inactive_count) * Int64(pageSize)
            / Unit.megabyte.rawValue
        let wired = Int64(data.wire_count) * Int64(pageSize)
            / Unit.megabyte.rawValue
        // Result of the compression. This is what you see in Activity Monitor
        let compressed = Int64(data.compressor_page_count) * Int64(pageSize)
            / Unit.megabyte.rawValue

        return [
            TealiumDataKey.memoryFree: free,
            TealiumDataKey.memoryInactive: inactive,
            TealiumDataKey.memoryWired: wired,
            TealiumDataKey.memoryActive: active,
            TealiumDataKey.memoryCompressed: compressed,
            TealiumDataKey.physicalMemory: physical,
            TealiumDataKey.appMemoryUsage: appMemoryUsed
        ]
    }
}
