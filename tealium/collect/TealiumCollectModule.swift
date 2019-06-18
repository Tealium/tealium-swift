//
//  TealiumCollectModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

/// Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
class TealiumCollectModule: TealiumModule {

    var collect: TealiumCollectProtocol?
    var config: TealiumConfig?
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1000,
                                   build: 4,
                                   enabled: true)
    }

    /// Enables the module and loads sets up a dispatcher
    ///
    /// - Parameter request: TealiumEnableRequest - the request from the core library to enable this module
    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true
        config = request.config
        if self.collect == nil {
            // Collect dispatch service
            let urlString = config?.optionalData[TealiumCollectKey.overrideCollectUrl] as? String
            // check if should use legacy (GET) dispatch method
            if config?.optionalData[TealiumCollectKey.legacyDispatchMethod] as? Bool == true {
                let urlString = urlString ?? TealiumCollect.defaultBaseURLString()
                self.collect = TealiumCollect(baseURL: urlString)
                didFinish(request)
            } else {
                let urlString = urlString ?? TealiumCollectPostDispatcher.defaultDispatchURL
                self.collect = TealiumCollectPostDispatcher(dispatchURL: urlString) { _ in
                    self.didFinish(request)
                }
            }
        }
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing
    ///
    /// - Parameter track: TealiumTrackRequest to be dispatched
    override func track(_ track: TealiumTrackRequest) {
        if isEnabled == false {
            didFinishWithNoResponse(track)
            return
        }
        var newTrack = track.data

        if track.data[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName {
            didFinishWithNoResponse(track)
            return
        }

        guard let collect = self.collect else {
            didFailToFinish(track,
                            error: TealiumCollectError.collectNotInitialized)
            return
        }

        if newTrack[TealiumKey.account] == nil,
            newTrack[TealiumKey.profile] == nil {
                newTrack[TealiumKey.account] = config?.account
                newTrack[TealiumKey.profile] = config?.profile
        }
        newTrack += track.data
        let trackRequest = TealiumTrackRequest(data: newTrack, completion: track.completion)

        // Send the current track call
        dispatch(trackRequest,
                 collect: collect)

    }

    /// Called when the module successfully finished processing a request
    ///
    /// - Parameters:
    /// - request: TealiumRequest that was processed
    /// - info: [String: Any]? containing additional information about the request processing
    func didFinish(_ request: TealiumRequest,
                   info: [String: Any]?) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: true,
                                             error: nil)
        response.info = info
        newRequest.moduleResponses.append(response)

        delegate?.tealiumModuleFinished(module: self,
                                        process: newRequest)
    }

    /// Called when the module failed for to complete a request
    ///
    /// - Parameters:
    /// - request: TealiumRequest that failed
    /// - info: [String: Any]? containing information about the failure
    /// - error: Error with precise information about the failure
    func didFailToFinish(_ request: TealiumRequest,
                         info: [String: Any]?,
                         error: Error) {
        var newRequest = request
        var response = TealiumModuleResponse(moduleName: type(of: self).moduleConfig().name,
                                             success: false,
                                             error: error)
        response.info = info
        newRequest.moduleResponses.append(response)
        delegate?.tealiumModuleFinished(module: self,
                                        process: newRequest)
    }

    /// Sends a track request to a specified dispatcher
    ///
    /// - Parameters:
    /// - track: TealiumTrackRequest to be processed
    /// - collect: TealiumCollectProtocol instance to be used for this dispatch
    func dispatch(_ track: TealiumTrackRequest,
                  collect: TealiumCollectProtocol) {

        var newData = track.data
        newData[TealiumKey.dispatchService] = TealiumCollectKey.moduleName

        if let profileOverride = config?.optionalData[TealiumCollectKey.overrideCollectProfile] as? String {
            newData[TealiumKey.profile] = profileOverride
        }

        collect.dispatch(data: newData, completion: { success, info, error in

            track.completion?(success, info, error)

            // Let the modules manager know we had a failure.
            if success == false {
                var localError = error
                if localError == nil { localError = TealiumCollectError.unknownIssueWithSend }
                self.didFailToFinish(track,
                                     info: info,
                                     error: localError!)
                return
            }

            var trackInfo = info ?? [String: Any]()
            trackInfo[TealiumKey.dispatchService] = TealiumCollectKey.moduleName
            trackInfo += [TealiumCollectKey.payload: track.data]

            // Another message to moduleManager of completed track, this time of
            //  modified track data.
            self.didFinish(track,
                           info: trackInfo)
        })
    }

    /// Disables the module
    ///
    /// - Parameter request: TealiumDisableRequest
    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        self.collect = nil
        didFinish(request)
    }

    deinit {
        self.config = nil
        self.collect = nil
    }

}
