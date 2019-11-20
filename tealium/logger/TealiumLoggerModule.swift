//
//  TealiumLoggerModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

#if logger
import TealiumCore
#endif

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
            moduleResponses.forEach({ response in
                logEnable(response)
            })
        case is TealiumDisableRequest:
            moduleResponses.forEach({ response in
                logDisable(response)
            })
        case is TealiumLoadRequest:
            logLoad(moduleResponses)
        case is TealiumSaveRequest:
            logSave(moduleResponses)
        case let request as TealiumReportRequest:
            logReport(request)
        case let request as TealiumTrackRequest:
            logTrack(request: request, responses: moduleResponses)
        case let request as TealiumBatchTrackRequest:
            let requests = request.trackRequests
            requests.enumerated().forEach {
                logTrack(request: $0.element, responses: moduleResponses,
                         index: (x: $0.offset, n: requests.count)
                         )

            }
        default:
            // Only print errors if detected in module responses.
            moduleResponses.forEach({ response in
                logError(response)
            })
        }
    }

    /// Logs module enable requests.
    ///
    /// - Parameter response: `TealiumModuleResponse`
    func logEnable(_ response: TealiumModuleResponse) {
        let successMessage = response.success == true ? "ENABLED" : "FAILED TO ENABLE"
        let message = "\(response.moduleName): \(successMessage)"
        logger?.log(message: message,
                    logLevel: .verbose)
    }

    /// Logs module disable requests.
    ///
    /// - Parameter response: `TealiumModuleResponse`
    func logDisable(_ response: TealiumModuleResponse) {
        let successMessage = response.success == true ? "ENABLED" : "FAILED TO DISABLE"
        let message = "\(response.moduleName): \(successMessage)"
        logger?.log(message: message,
                    logLevel: .verbose)
    }

    /// Logs module errors.
    ///
    /// - Parameter response: `TealiumModuleResponse`
    func logError(_ response: TealiumModuleResponse) {
        guard let error = response.error else {
            return
        }
        let message = "\(response.moduleName): Encountered error: \(error)"
        logger?.log(message: message,
                    logLevel: .errors)
    }

    /// Logs persistent data load requests.
    ///
    /// - Parameter responses: `[TealiumModuleResponse]`
    func logLoad(_ responses: [TealiumModuleResponse]) {
        var successes = 0
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
            logger?.log(message: message, logLevel: .verbose)
            return
        }
        // Failed to load
        let message = "FAILED to load data. Possibly no data storage modules enabled."
        logger?.log(message: message,
                    logLevel: .errors)
    }

    /// Logs module report requests.
    ///
    /// - Parameter response: `TealiumReportRequest`
    func logReport(_ request: TealiumReportRequest) {
        let message = "\(request.message)"
        logger?.log(message: message,
                    logLevel: .verbose)
    }

    /// Logs persistent data save requests.
    ///
    /// - Parameter responses: `[TealiumModuleResponse]`
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
        logger?.log(message: message,
                    logLevel: .errors)
    }

    /// Logs track requests.
    ///
    /// - Parameters:
    ///     - request: `TealiumTrackRequest`
    ///     - responses: `[TealiumModuleResponse]`
    ///     - index: `(x: Int, n: Int)?` -  the number of the current track request in the batch vs total
    func logTrack(request: TealiumTrackRequest,
                  responses: [TealiumModuleResponse],
                  index: (x: Int, n: Int)? = nil
                  ) {
        let trackNumber = Tealium.numberOfTrackRequests.incrementAndGet()
        var message = """
        \n=====================================
        ▶️[Track #\(trackNumber)]: \(request.trackDictionary[TealiumKey.event] as? String ?? "")
        =====================================\n
        """

        if let index = index {
            message += """

            Batch track: Request #\(index.x + 1) out of \(index.n) total

            """
        }

        if responses.count > 0 {
            message += "Module Responses:\n"
        }

        responses.enumerated().forEach {
            let index = $0.offset + 1
            let response = $0.element
            let successMessage = response.success == true ? "SUCCESSFUL TRACK ✅" : "FAILED TO TRACK ⚠️"
            var trackMessage = "\(index). \(response.moduleName): \(successMessage)"
            if !response.success, let error = response.error {
             trackMessage += "\n🔺 \(error.localizedDescription)"
            }
            message = "\(message)\(trackMessage)\n"
        }

        message += "\nTRACK REQUEST PAYLOAD:\n"

        if let jsonString = request.trackDictionary.toJSONString() {
            message += jsonString
        } else {
            // peculiarity with AnyObject printing: quotes are randomly omitted from values
            message += "\(request.trackDictionary as AnyObject)"
        }

        message = "\(message)[Track # \(trackNumber)] ⏹\n"

        logger?.log(message: message,
                    logLevel: .verbose)
    }

    /// Logs message with a prefix containing the module name.
    ///
    /// - Parameters:
    ///     - module: `TealiumModule` requesting the operation
    ///     - message: `String` containing the log message
    ///     - logLevel: `TealiumLogLevel` for the message
    func logWithPrefix(fromModule module: TealiumModule,
                       message: String,
                       logLevel: TealiumLogLevel) {

        let moduleConfig = type(of: module).moduleConfig()
        let newMessage = "\(moduleConfig.name) module.\(moduleConfig.build): \(message)"
        logger?.log(message: newMessage, logLevel: logLevel)
    }

}
