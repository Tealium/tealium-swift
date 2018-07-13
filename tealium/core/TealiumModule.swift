//
//  TealiumModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
//  Build 3

import Foundation

public protocol TealiumModuleDelegate: class {

    /// Called by modules after they've completed a requested command or encountered an error.
    ///
    /// - Parameters:
    ///   - module: Module that finished processing.
    ///   - process: The TealiumRequest completed.
    func tealiumModuleFinished(module: TealiumModule,
                               process: TealiumRequest)

    /// Called by module requesting an library operation.
    ///
    /// - Parameters:
    ///   - module: Module making request.
    ///   - process: TealiumModuleProcessType requested.
    func tealiumModuleRequests(module: TealiumModule?,
                               process: TealiumRequest)

}

// Function(s) required by every subclass of the TealiumModule
public protocol TealiumModuleProtocol {
    func handle(_ request: TealiumRequest)
}

/**
 Base class for all Tealium feature modules.
 */
open class TealiumModule: TealiumModuleProtocol {

    weak var delegate: TealiumModuleDelegate?
    public var isEnabled: Bool = false

    /// Constructor.
    ///
    /// - Parameter delegate: Delegate for module, usually the ModulesManager.
    required public init(delegate: TealiumModuleDelegate?) {
        self.delegate = delegate
    }

    // MARK: OVERRIDABLE FUNCTIONS
    class open func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: "default",
                                   priority: 0,
                                   build: 0,
                                   enabled: false)
    }

    // MARK: PUBLIC OVERRIDES

    /// Generic handling of requests from ModulesManager. Individual modules will
    ///   need to determine how to handle various request types. If a module does
    ///   not do anything for a given request type, then it should execute the
    ///   didFinishWithNoReponse() method. Typically all modules will handle
    ///   at least the minimum enable & disable functions.
    ///
    /// - Parameter request: TealiumRequest type to be processed.
    open func handle(_ request: TealiumRequest) {
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

    /// Handle enable completion by another module (ie logging).
    ///
    /// - Parameter fromModule: Module originally reporting enable.
    /// - Parameter process: Related TealiumRequest
    open func handleReport(_ request: TealiumRequest) {

        // If received - then all modules have finished processing the given request.
        // No need to report back to ModuleManager as this is a one way notification
        //  from the ModulesManager to the module.

    }

    /// Most modules will want to be able to be enabled.
    ///
    /// - Parameter request: TealiumEnableRequest.
    open func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        didFinish(request)
    }

    /// Most modules will want to be able to be disabled.
    ///
    /// - Parameter request: TealiumDisableRequest.
    open func disable(_ request: TealiumDisableRequest) {

        isEnabled = false
        didFinish(request)

    }

    // MARK: SUBCLASS CONVENIENCE METHODS

    /// Should be called by modules after processing requests, unless needing to
    ///     halt further processing by other modules down the priority chain.
    ///     This method auto updates the request's moduleResponse list with
    ///     the subclass's module name & success = true. No need to override.
    ///
    /// - Parameter request: Any TealiumRequest to pass back to the ModulesManager.
    open func didFinish(_ request: TealiumRequest) {
        var newRequest = request
        let response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    /// Should be called by modules after processing requests, unless needing to
    ///     halt further processing by other modules down the priority chain.
    ///     This method auto updates the request's moduleResponse list with
    ///     the subclass's module name & success = true. No need to override.
    ///
    /// - Parameter request: Any TealiumRequest to pass back to the ModulesManager.
    open func didFinish(_ request: TealiumRequest, _ error: Error?) {

        var newRequest = request

        let response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: error)
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    /// Called by a module that did not process a request, or will process
    ///     asynchronously and can pass the request down the priority chain at time of
    ///     call. Does not amend the request's moduleResponse with the sub classed
    ///     module's info. No need to override.
    ///
    /// - Parameter request: The original TealiumRequest.
    open func didFinishWithNoResponse(_ request: TealiumRequest) {

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: request)
    }

    /// Called by a module that has encountered an error when processing a request.
    ///     No need to override.
    ///
    /// - Parameters:
    ///   - request: TealiumRequest to send back to the ModulesManager for futher processing.
    ///   - error: Error associated with the failure.
    open func didFailToFinish(_ request: TealiumRequest,
                              error: Error) {

        var newRequest = request
        let response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: false,
                                             error: error)
        newRequest.moduleResponses.append(response)

        self.delegate?.tealiumModuleFinished(module: self,
                                             process: newRequest)
    }

    /// Majority of modules will want to manipulate or deliver track events - but
    ///     not all, so default behavior is to disregard. Override in subclasses
    ///     to process.
    ///
    /// - Parameter request: TealiumTrackRequest to process.
    open func track(_ request: TealiumTrackRequest) {
        didFinishWithNoResponse(request)
    }

}

extension TealiumModule: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self).moduleConfig().name).module"
    }
}

extension TealiumModule: Equatable {

    public static func == (lhs: TealiumModule, rhs: TealiumModule ) -> Bool {
        return type(of: lhs).moduleConfig() == type(of: rhs).moduleConfig()
    }

}

extension TealiumModule: Hashable {

    public var hashValue: Int {
        return type(of: self).moduleConfig().name.hash
    }

}
