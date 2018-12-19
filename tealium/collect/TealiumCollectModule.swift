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

// MARK: 
// MARK: CONSTANTS

enum TealiumCollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let overrideCollectProfile = "tealium_override_collect_profile"
    static let payload = "payload"
    static let responseHeader = "response_headers"
    public static let errorHeaderKey = "X-Error"
    public static let legacyDispatchMethod = "legacy_dispatch_method"
}

enum TealiumCollectError: Error {
    case collectNotInitialized
    case unknownResponseType
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
}

// MARK: 
// MARK: EXTENSIONS

public extension Tealium {

    func collect() -> TealiumCollectProtocol? {
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }

        return collectModule.collect
    }
}

public extension TealiumConfig {

    func setCollectOverrideURL(string: String) {
        if string.contains("vdata") {
            var urlString = string
            var lastChar: Character?
            lastChar = urlString.last

            if lastChar != "&" {
                urlString += "&"
            }
            optionalData[TealiumCollectKey.overrideCollectUrl] = urlString
        } else {
            optionalData[TealiumCollectKey.overrideCollectUrl] = string
        }

    }

    func setCollectOverrideProfile(profile: String) {
        optionalData[TealiumCollectKey.overrideCollectProfile] = profile
    }

    func setLegacyDispatchMethod(_ shouldUseLegacyDispatch: Bool) {
        optionalData[TealiumCollectKey.legacyDispatchMethod] = shouldUseLegacyDispatch
    }

}

// MARK: 
// MARK: MODULE SUBCLASS

/**
 Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
 */
class TealiumCollectModule: TealiumModule {

    var collect: TealiumCollectProtocol?
    var config: TealiumConfig?
    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1000,
                                   build: 4,
                                   enabled: true)
    }

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

    override func disable(_ request: TealiumDisableRequest) {
        isEnabled = false
        self.collect = nil
        didFinish(request)
    }

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

    deinit {
        self.config = nil
        self.collect = nil
    }

}
