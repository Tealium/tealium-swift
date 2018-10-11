//
//  TealiumLoggerModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

enum TealiumLoggerKey {
    static let moduleName = "logger"
    static let logLevelConfig = "com.tealium.logger.loglevel"
    static let shouldEnable = "com.tealium.logger.enable"
}

public enum TealiumLogLevelValue {
    static let errors = "errors"
    static let none = "none"
    static let verbose = "verbose"
    static let warnings = "warnings"
}

public enum TealiumLoggerModuleError: Error {
    case moduleDisabled
    case noAccount
    case noProfile
    case noEnvironment
}

let defaultTealiumLogLevel: TealiumLogLevel = .errors

public enum TealiumLogLevel: Int, Comparable {
    case none = 0
    case errors = 1
    case warnings = 2
    case verbose = 3

    var description: String {
        switch self {
        case .errors:
            return TealiumLogLevelValue.errors
        case .warnings:
            return TealiumLogLevelValue.warnings
        case .verbose:
            return TealiumLogLevelValue.verbose
        default:
            return TealiumLogLevelValue.none
        }
    }

    static func fromString(_ string: String) -> TealiumLogLevel {
        switch string.lowercased() {
        case TealiumLogLevelValue.errors:
            return .errors
        case TealiumLogLevelValue.warnings:
            return .warnings
        case TealiumLogLevelValue.verbose:
            return .verbose
        default:
            return .none
        }
    }

    public static func < (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func > (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue > rhs.rawValue
    }

    public static func <= (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue <= rhs.rawValue
    }

    public static func >= (lhs: TealiumLogLevel, rhs: TealiumLogLevel) -> Bool {
        return lhs.rawValue >= rhs.rawValue
    }
}

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func logger() -> TealiumLogger? {
        guard let module = modulesManager.getModule(forName: TealiumLoggerKey.moduleName) as? TealiumLoggerModule else {
            return nil
        }

        return module.logger
    }
}

public extension TealiumConfig {

    func getLogLevel() -> TealiumLogLevel {
        if let level = self.optionalData[TealiumLoggerKey.logLevelConfig] as? TealiumLogLevel {
            return level
        }

        // Default
        return defaultTealiumLogLevel
    }

    func setLogLevel(logLevel: TealiumLogLevel) {
        self.optionalData[TealiumLoggerKey.logLevelConfig] = logLevel
    }
}

// MARK: 
// MARK: MODULE

/// Module for adding basic console log output.
class TealiumLoggerModule: TealiumModule {

    var logger: TealiumLogger?

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumLoggerKey.moduleName,
                                   priority: 100,
                                   build: 3,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true

        if logger == nil {
            let config = request.config
            let logLevel = config.getLogLevel()
            let id = "\(config.account):\(config.profile):\(config.environment)"
            logger = TealiumLogger(loggerId: id, logLevel: logLevel)
        }

        delegate?.tealiumModuleRequests(module: self,
                                        process: TealiumReportNotificationsRequest())
        didFinish(request)
    }

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        logger = nil
        didFinish(request)
    }

    override func handleReport(_ request: TealiumRequest) {
        let moduleResponses = request.moduleResponses

        switch request {
        case is TealiumEnableRequest:
            moduleResponses.forEach ({ response in
                logEnable(response)
            })
        case is TealiumDisableRequest:
            moduleResponses.forEach ({ response in
                logDisable(response)
            })
        case is TealiumLoadRequest:
            logLoad(moduleResponses)
        case is TealiumSaveRequest:
            logSave(moduleResponses)
        case is TealiumReportRequest:
            moduleResponses.forEach({ _ in
                logReport(request)
            })
        case is TealiumTrackRequest:
            moduleResponses.forEach({ response in
                if response.info == nil {
                    return
                }
                logTrack(response)
            })
        default:
            // Only print errors if detected in module responses.
            moduleResponses.forEach({ response in
                logError(response)
            })
        }
    }

    func logEnable(_ response: TealiumModuleResponse) {
        let successMessage = response.success == true ? "ENABLED" : "FAILED TO ENABLE"
        let message = "\(response.moduleName): \(successMessage)"
        _ = logger?.log(message: message,
                        logLevel: .verbose)
    }

    func logDisable(_ response: TealiumModuleResponse) {
        let successMessage = response.success == true ? "ENABLED" : "FAILED TO DISABLE"
        let message = "\(response.moduleName): \(successMessage)"
        _ = logger?.log(message: message,
                        logLevel: .verbose)
    }

    func logError(_ response: TealiumModuleResponse) {
        guard let error = response.error else {
            return
        }
        let message = "\(response.moduleName): Encountered error: \(error)"
        _ = logger?.log(message: message,
                        logLevel: .errors)
    }

    func logLoad(_ responses: [TealiumModuleResponse]) {
        var successes = 0
        // Swift's native Error type seems to be leaky. Using Any fixes the leak.
        var errors = [Error]()
        responses.forEach { response in
            if response.success == true {
                successes += 1
            }
            if let error = response.error {
                errors.append(error)
            }
        }
        if successes > 0 && errors.count == 0 {
            return
        } else if successes > 0 && errors.count > 0 {
            var message = ""
            errors.forEach({ err in
                message += "\(err.localizedDescription)\n"
            })
            _ = logger?.log(message: message, logLevel: .verbose)
            return
        }
        // Failed to load
        let message = "FAILED to load data. Possibly no data storage modules enabled."
        _ = logger?.log(message: message,
                        logLevel: .errors)
    }

    func logReport(_ request: TealiumRequest) {
        guard let request = request as? TealiumReportRequest else {
            return
        }
        let message = "\(request.message)"
        _ = logger?.log(message: message,
                        logLevel: .verbose)
    }

    func logSave(_ responses: [TealiumModuleResponse]) {
        var successes = 0
        responses.forEach { response in
            if response.success == true {
                successes += 1
            }
        }
        if successes > 0 {
            return
        }
        // Failed to load
        let message = "FAILED to save data. Possibly no storage persistence modules enabled."
        _ = logger?.log(message: message,
                        logLevel: .errors)
    }

    func logTrack(_ response: TealiumModuleResponse) {
        let successMessage = response.success == true ? "SUCCESSFUL TRACK" : "FAILED TO TRACK"
        let message = "\(response.moduleName): \(successMessage)\nINFO:\n\(response.info as AnyObject)"
        _ = logger?.log(message: message,
                        logLevel: .verbose)
    }

    func logWithPrefix(fromModule: TealiumModule,
                       message: String,
                       logLevel: TealiumLogLevel) {

        let moduleConfig = type(of: fromModule).moduleConfig()
        let newMessage = "\(moduleConfig.name) module.\(moduleConfig.build): \(message)"
        _ = logger?.log(message: newMessage, logLevel: logLevel)
    }

}
