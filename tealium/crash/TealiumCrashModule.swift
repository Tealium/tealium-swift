//
//  TealiumCrashModule.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 2/8/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if !COCOAPODS
import TealiumCore
#endif

public enum TealiumCrashKey {
    public static let moduleName = "crash"
    public static let uuid = "crash_uuid"
    public static let processId = "crash_process_id"
    public static let processPath = "crash_process_path"
    public static let parentProcess = "crash_parent_process"
    public static let parentProcessId = "crash_parent_process_id"
    public static let exceptionName = "crash_name"
    public static let exceptionReason = "crash_cause"
    public static let signalCode = "crash_signal_code"
    public static let signalName = "crash_signal_name"
    public static let signalAddress = "crash_signal_address"
    public static let libraries = "crash_libraries"
    public static let threads = "crash_threads"
    public static let deviceMemoryUsageLegacy = "device_memory_usage"
    public static let deviceMemoryUsage = "app_memory_usage"
    public static let deviceMemoryAvailable = "device_memory_available"
    public static let deviceMemoryAvailableLegacy = "memory_free"
    public static let deviceOsBuild = "device_os_build"
}

public enum TealiumCrashImageKey {
    public static let baseAddress = "baseAddress"
    public static let imageName = "imageName"
    public static let imageUuid = "imageUuid"
    public static let imageSize = "imageSize"
    public static let codeType = "codeType"
    public static let architecture = "arch"
    public static let typeEncoding = "typeEncoding"
}

public enum TealiumCrashThreadKey {
    public static let registers = "registers"
    public static let crashed = "crashed"
    public static let threadId = "threadId"
    public static let threadNumber = "threadNumber"
    public static let priority = "priority"

    public static let stack = "stack"
    public static let instructionPointer = "instructionPointer"
    public static let symbolInfo = "symbolInfo"
    public static let symbolName = "symbolName"
    public static let symbolStartAddress = "symbolStartAddr"
}

class TealiumCrashModule: TealiumModule {

    var crashReporter: TealiumCrashReporterType?

    required public init(delegate: TealiumModuleDelegate?) {
        // hack because of existing class hierarchy
        crashReporter = TealiumCrashReporter()
        super.init(delegate: delegate)
    }

    init(delegate: TealiumModuleDelegate?, crashReporter: TealiumCrashReporterType) {
        self.crashReporter = crashReporter
        super.init(delegate: delegate)
    }

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCrashKey.moduleName,
                                   priority: 410,
                                   build: 0,
                                   enabled: true)
    }

    override func handle(_ request: TealiumRequest) {
        if let request = request as? TealiumEnableRequest {
            enable(request)
        } else if let request = request as? TealiumDisableRequest {
            disable(request)
        } else if let request = request as? TealiumTrackRequest {
            track(request)
        } else {
            didFinishWithNoResponse(request)
        }
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        _ = crashReporter?.enable()
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false

        // shut down crash reporter
        _ = crashReporter?.disable()
        crashReporter = nil
        didFinish(request)
    }

    override func track(_ track: TealiumTrackRequest) {
        if !isEnabled {
            didFinishWithNoResponse(track)
            return
        }

        guard let crashReporter = crashReporter else {
            didFinishWithNoResponse(track)
            return
        }

        if crashReporter.hasPendingCrashReport() {
            guard let data = crashReporter.getData() else {
                return didFinishWithNoResponse(track)
            }

            let newTrack = TealiumTrackRequest(data: data, completion: { [weak crashReporter] _, _, _ in
                _ = crashReporter?.purgePendingCrashReport()
            })
            didFinish(newTrack)
        } else {
            // no pending crash report
            didFinishWithNoResponse(track)
        }
    }
}
