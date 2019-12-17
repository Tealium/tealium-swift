//
//  TealiumModulesManager.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

/// Coordinates optional modules with primary Tealium class.
open class TealiumModulesManager: NSObject {

    weak var queue: ReadWrite?
    public var modules = [TealiumModule]()
    public var isEnabled = true
    public var modulesRequestingReport = [Weak<TealiumModule>]()
    public let timeoutMillisecondIncrement = 500
    public var timeoutMillisecondCurrent = 0
    public var timeoutMillisecondMax = 10_000
    weak var tealiumInstance: Tealium?

    /// Sets up active modules from config￼.
    ///
    /// - Parameter config: `TealiumConfig` instance
    func setupModulesFrom(config: TealiumConfig) {
        let modulesList = config.getModulesList()
        let newModules = TealiumModules.initializeModulesFor(modulesList, assigningDelegate: self)
        self.modules = newModules.prioritized()
    }

    /// Updates the currently active modules from config￼.
    ///
    /// - Parameter config: `TealiumConfig` instance
    public func update(config: TealiumConfig) {
        update(config: config, enableCompletion: nil)
    }

    /// Updates the currently active modules from config￼.
    ///
    /// - Parameter config: `TealiumConfig` instance￼
    /// - Parameter completion: `TealiumEnableCompletion?` to be called when modules have been initialized
    public func update(config: TealiumConfig,
                       enableCompletion: TealiumEnableCompletion?) {
        self.modules.removeAll()
        enable(config: config,
               enableCompletion: enableCompletion)
    }

    /// Enables modules￼.
    ///
    /// - Parameters:
    ///     - config: `TealiumConfig` instance￼
    ///     - completion: `TealiumEnableCompletion?` to be called when modules have been initialized￼
    ///     - tealiumInstance: `Tealium?` instance used to determine if Tealium is currently active
    public func enable(config: TealiumConfig,
                       enableCompletion: TealiumEnableCompletion?,
                       tealiumInstance: Tealium? = nil) {
        self.setupModulesFrom(config: config)
        self.tealiumInstance = tealiumInstance
        self.queue = TealiumQueues.backgroundConcurrentQueue
        let request = TealiumEnableRequest(config: config,
                                           enableCompletion: enableCompletion)
        self.modules.first?.handle(request)
    }

    /// Tear down all modules
    public func disable() {
        isEnabled = false
        let request = TealiumDisableRequest()
        self.modules.first?.handle(request)
    }

    /// Retrieves a currently-active module￼.
    ///
    /// - Parameter name: `String`
    /// - Returns: `TealiumModule?`
    public func getModule(forName name: String) -> TealiumModule? {
        return modules.first(where: { type(of: $0).moduleConfig().name == name })
    }

    /// Checks if all modules ready.
    ///
    /// - Returns: `Bool` `true` if all modules ready
    public func allModulesReady() -> Bool {
        for module in modules where module.isEnabled == false {
            return false
        }
        return true
    }

    /// Returns list of modules not currently ready to process events￼.
    ///
    /// - Parameter modules: `[TealiumModule]`
    /// - Returns: `[TealiumModule]` containing all modules not yet enabled
    public func modulesNotReady(_ modules: [TealiumModule]) -> [TealiumModule] {
        var result = [TealiumModule]()
        for module in modules where module.isEnabled == false {
            result.append(module)
        }
        return result
    }

    /// Passes `TealiumTrackRequest` or `TealiumBatchTrackRequest` to modules￼.
    ///
    /// - Parameter track: `TealiumRequest`
    public func track(_ track: TealiumRequest) {
        guard let firstModule = modules.first else {
            track.completion?(false, nil, TealiumModulesManagerError.noModules)
            return
        }

        if isEnabled == false {
            track.completion?(false, nil, TealiumModulesManagerError.isDisabled)
            return
        }

        let notReady = modulesNotReady(modules)

        if notReady.isEmpty == false {
            timeoutMillisecondCurrent += timeoutMillisecondIncrement
            if timeoutMillisecondCurrent >= timeoutMillisecondMax {
                var request: TealiumEnqueueRequest
                switch track {
                case let track as TealiumTrackRequest:
                    request = TealiumEnqueueRequest(data: track, completion: nil)
                case let track as TealiumBatchTrackRequest:
                    request = TealiumEnqueueRequest(data: track, completion: nil)
                default:
                    return
                }
                // if modules are not ready after timeout, event is queued until later
                tealiumModuleRequests(module: nil, process: request)
                return
            }
            let delay = DispatchTime.now() + .milliseconds(timeoutMillisecondCurrent)
            queue?.write(after: delay) {
                // Put call into end of queue until all modules ready.
                self.track(track)
            }
            return
        }

        self.timeoutMillisecondCurrent = 0  // reset

        firstModule.handle(track)
    }

    /// Reports to listening modules when a request has been processed by all modules￼.
    ///
    /// - Parameters:
    ///     - modules: `[Weak<TealiumModule>]` to receive report
    ///     - request: `TealiumRequest` that has been processed
    public func reportToModules(_ modules: [Weak<TealiumModule>],
                                request: TealiumRequest) {
        for moduleRef in modules {
            guard let module = moduleRef.value else {
                // Module has been dereferenced
                continue
            }
            module.handleReport(request)
        }
    }
}

// MARK: TEALIUM MODULE DELEGATE
extension TealiumModulesManager: TealiumModuleDelegate {

    /// Called by a module that has finished processing a request￼.
    ///
    /// - Parameters:
    ///     - module: `TealiumModule` that has finished processing the request￼
    ///     - process: `TealiumRequest` that has been processed
    public func tealiumModuleFinished(module: TealiumModule,
                                      process: TealiumRequest) {
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            guard let nextModule = self.modules.next(after: module) else {

                // If enable call set isEnable
                if let process = process as? TealiumEnableRequest {
                    self.isEnabled = true
                    // Should never be nil at this point, but we are running on a background thread, so there's a very slim chance. This may happen in unit tests
                    if self.tealiumInstance != nil {
                     process.enableCompletion?(process.moduleResponses)
                    }
                }
                // Last module has finished processing
                self.reportToModules(self.modulesRequestingReport,
                                     request: process)

                return
            }

            nextModule.handle(process)
        }
    }

    /// Called by a module requesting a new operation￼.
    ///
    /// - Parameters:
    ///     - module: `TealiumModule?` requesting the operation￼
    ///     - process: `TealiumRequest` to be processed
    public func tealiumModuleRequests(module: TealiumModule?,
                                      process: TealiumRequest) {
        // Module wants to be notified when last module has finished processing
        //  any requests.
        if process as? TealiumReportNotificationsRequest != nil {
            let existingRequestModule = modulesRequestingReport.filter { $0.value == module }
            if existingRequestModule.count == 0 {
                if let module = module {
                    modulesRequestingReport.append(Weak(value: module))
                }
            }

            return
        }

        // Module wants to notify any listening modules of status.
        if let process = process as? TealiumReportRequest {
            reportToModules(modulesRequestingReport,
                            request: process)
            return
        }

        if let track = process as? TealiumTrackRequest {
            self.track(track)
            return
        }

        if let track = process as? TealiumBatchTrackRequest {
            self.track(track)
            return
        }

        if let enable = process as? TealiumEnableRequest {
            self.enable(config: enable.config,
                        enableCompletion: enable.enableCompletion)
            return
        }

        if process as? TealiumDisableRequest != nil {
            self.disable()
            return
        }

        if isEnabled == false {
            return
        }

        // Pass request to other modules - Regular behavior
        modules.first?.handle(process)
    }
}

// MARK: MODULEMANAGER EXTENSIONS
extension Array where Element: TealiumModule {

    /// Convenience for sorting Arrays of TealiumModules by priority number: Lower numbers going first.
    ///
    /// - Returns: `[TealiumModule]` ordered list of modules
    func prioritized() -> [TealiumModule] {
        return self.sorted {
            type(of: $0).moduleConfig().priority < type(of: $1).moduleConfig().priority
        }

    }

    /// Get all existing module names, in current order.
    /// 
    /// - Returns: Array of module names.
    func moduleNames() -> [String] {
        return self.map { type(of: $0).moduleConfig().name }
    }

}

extension Array where Element: Equatable {
    /// Convenience for getting the next object in a given array.
    func next(after: Element) -> Element? {
        for itr in 0..<self.count {
            let object = self[itr]
            if object == after {

                if itr + 1 < self.count {
                    return self[itr + 1]
                }
            }
        }

        return nil
    }
}
