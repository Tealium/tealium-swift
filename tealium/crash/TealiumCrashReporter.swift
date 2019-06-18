//
//  TealiumCrashReporter.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 2/15/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if !COCOAPODS
import TealiumCore
import TealiumDeviceData
#endif
import TealiumCrashReporteriOS

/// Defines the specifications for TealiumCrashReporterType.  Concrete TealiumCrashReporters must implement this protocol.
public protocol TealiumCrashReporterType: class {
    func enable() -> Bool

    func disable()

    func hasPendingCrashReport() -> Bool

    func purgePendingCrashReport()

    func getData() -> [String: Any]?
}

public class TealiumCrashReporter: TealiumCrashReporterType {

    var crashReporter = TEALPLCrashReporter()
    public var crashData: [String: Any]?

    /// Enables crashReporter internal type.
    public func enable() -> Bool {
        return crashReporter.enable()
    }

    /// Checks if a crash report exists.
    public func hasPendingCrashReport() -> Bool {
        return crashReporter.hasPendingCrashReport()
    }

    /// Removes any existing crash report on `disable()`.
    public func disable() {
        crashReporter.purgePendingCrashReport()
    }

    /// Removes any existing crash report.
    public func purgePendingCrashReport() {
        crashReporter.purgePendingCrashReport()
    }

    /// Invokes a crash
    /// - Parameters:
    /// - name: name of the crash
    /// - reason: reason for the crash
    public class func invokeCrash(name: String, reason: String) {
        NSException(name: NSExceptionName(rawValue: name), reason: reason, userInfo: nil).raise()
    }

    /// Gets crash data if crash module is enabled.
    public func getData() -> [String: Any]? {
        do {
            guard crashData == nil else {
                return crashData
            }
            let crashReportData = crashReporter.loadPendingCrashReportData()
            guard let crashReport = try? TEALPLCrashReport(data: crashReportData) else {
                return nil
            }
            let crash = TealiumPLCrash(crashReport: crashReport, deviceDataCollection: TealiumDeviceData())
            var data = [String: Any]()
            data += crash.getData(truncate: true)

            return data
        }
    }
}
