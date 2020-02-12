//
//  TealiumVisitorServiceModule.swift
//  tealium-swift
//
//  Created by Christina Sund on 6/11/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public class TealiumVisitorServiceModule: TealiumModule {

    var visitorProfileManager: TealiumVisitorProfileManagerProtocol?
    var diskStorage: TealiumDiskStorageProtocol!
    var visitorId: String?
    var firstEventSent = false

    override public class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumVisitorProfileConstants.moduleName,
                                   priority: 1150,
                                   build: 1,
                                   enabled: true)
    }

    override public func handle(_ request: TealiumRequest) {
        switch request {
        case let request as TealiumEnableRequest:
            enable(request)
        case let request as TealiumDisableRequest:
            disable(request)
        case let request as TealiumTrackRequest:
            track(request)
        case let request as TealiumBatchTrackRequest:
            batchTrack(request)
        case let request as TealiumUpdateConfigRequest:
            updateConfig(request)
        default:
            didFinishWithNoResponse(request)
        }
    }

    /// Enable function required by TealiumModule.
    override public func enable(_ request: TealiumEnableRequest) {
        self.enable(request, diskStorage: nil)
    }

    /// Enables the module and starts the Visitor Profile Manager instance.
    ///
    /// - Parameter request: `TealiumEnableRequest` - the request from the core library to enable this module
    public func enable(_ request: TealiumEnableRequest,
                       diskStorage: TealiumDiskStorageProtocol? = nil,
                       visitor: TealiumVisitorProfileManagerProtocol? = nil) {
        if self.diskStorage == nil {
            self.diskStorage = diskStorage ?? TealiumDiskStorage(config: request.config, forModule: TealiumVisitorProfileConstants.moduleName, isCritical: false)
        }

        isEnabled = true
        guard visitor != nil else {
            visitorProfileManager = TealiumVisitorProfileManager(config: request.config,
                                                                 delegates: request.config.visitorServiceDelegates,
                                                                 diskStorage: self.diskStorage)

            if !request.bypassDidFinish {
                didFinish(request)
            }
            return
        }
        visitorProfileManager = visitor

    }

    override public func updateConfig(_ request: TealiumUpdateConfigRequest) {
        let newConfig = request.config.copy
        if newConfig != self.config {
            self.config = newConfig
            self.diskStorage = TealiumDiskStorage(config: newConfig, forModule: TealiumVisitorProfileConstants.moduleName, isCritical: false)
            var enableRequest = TealiumEnableRequest(config: newConfig, enableCompletion: nil)
            enableRequest.bypassDidFinish = true
            enable(enableRequest)
        }
        didFinish(request)
    }

    /// Disables the module.
    ///
    /// - Parameter request: `TealiumDisableRequest` - the request from the core library to disable this module
    override public func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        didFinish(request)
    }

    /// Sets the visitor id within the visitor profile retriever upon a track request. Also signals to the visitor profile manager
    /// that the first event has been sent.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be considered for processing.
    override public func track(_ request: TealiumTrackRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(request)
            return
        }
        let request = addModuleName(to: request)

        guard let visitorId = request.visitorId else {
                didFinishWithNoResponse(request)
            return
        }
        retrieveProfile(visitorId: visitorId)

        didFinishWithNoResponse(request)
    }

    func batchTrack(_ request: TealiumBatchTrackRequest) {
        guard isEnabled else {
            didFinishWithNoResponse(request)
            return
        }

        guard let lastRequest = request.trackRequests.last else {
            didFinishWithNoResponse(request)
            return
        }
        guard let visitorId = lastRequest.visitorId else {
            didFinishWithNoResponse(request)
            return
        }
        retrieveProfile(visitorId: visitorId)

        didFinishWithNoResponse(request)
    }

    func retrieveProfile(visitorId: String) {
        // wait before triggering refresh, to give event time to process
        TealiumQueues.backgroundConcurrentQueue.write(after: .now() + 2.1) {
            guard self.firstEventSent else {
                self.firstEventSent = true
                self.visitorProfileManager?.startProfileUpdates(visitorId: visitorId)
                return
            }
            self.visitorProfileManager?.requestVisitorProfile()
        }
    }
}
