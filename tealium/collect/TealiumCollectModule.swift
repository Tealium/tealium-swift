//
//  TealiumCollectModule.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/7/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation

// MARK: 
// MARK: CONSTANTS

enum TealiumCollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let payload = "payload"
    static let responseHeader = "response_headers"
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

extension Tealium {

    /**
     Deprecated - use the track(title: String, data: [String:Any]?, completion:((_ success: Bool, _ error: Error?)->Void) function instead. Convience method to track event with optional data.
     
     - parameters:
        - encodedURLString: Encoded string that will be used for the end point for the request
        - completion: Optional callback
     */
    @available(*, deprecated, message: "No longer supported. Will be removed next version.")
    func track(encodedURLString: String,
               completion: ((_ successful: Bool, _ encodedURLString: String, _ error: NSError?) -> Void)?) {
        collect()?.send(finalStringWithParams: encodedURLString,
                        completion: { success, info, _ in

                // Make new call but return empty responses for encodedURLString and error
                var encodedURLString = ""
                if let encodedURLStringRaw = info?[TealiumCollectKey.encodedURLString] as? String {
                    encodedURLString = encodedURLStringRaw
                }

                completion?(success, encodedURLString, nil)
        })
    }

    public func collect() -> TealiumCollect? {
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }

        return collectModule.collect
    }
}

public extension TealiumConfig {

    func setCollectOverrideURL(string: String) {
        optionalData[TealiumCollectKey.overrideCollectUrl] = string
    }

}

// MARK: 
// MARK: MODULE SUBCLASS

/**
 Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
 */
class TealiumCollectModule: TealiumModule {

    var collect: TealiumCollect?

    override class func moduleConfig() -> TealiumModuleConfig {
        return TealiumModuleConfig(name: TealiumCollectKey.moduleName,
                                   priority: 1000,
                                   build: 4,
                                   enabled: true)
    }

    override func enable(_ request: TealiumEnableRequest) {
        isEnabled = true

        if self.collect == nil {
            // Collect dispatch service
            var urlString: String
            if let collectURLString = request.config.optionalData[TealiumCollectKey.overrideCollectUrl] as? String {
                urlString = collectURLString
            } else {
                urlString = TealiumCollect.defaultBaseURLString()
            }
            self.collect = TealiumCollect(baseURL: urlString)
        }

        didFinish(request)
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

        if track.data[TealiumKey.event] as? String == TealiumConsentConstants.updateConsentCookieEventName {
            didFinishWithNoResponse(track)
            return
        }

        guard let collect = self.collect else {
            didFailToFinish(track,
                            error: TealiumCollectError.collectNotInitialized)
            return
        }

        // Send the current track call
        dispatch(track,
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
                  collect: TealiumCollect) {

        var newData = track.data
        newData[TealiumKey.dispatchService] = TealiumCollectKey.moduleName

        collect.dispatch(data: newData, completion: { [weak self] success, info, error in

            // if self deallocated, stop further track processing
            guard self != nil else {
                return
            }

            track.completion?(success, info, error)

            // Let the modules manager know we had a failure.
            if success == false {
                var localError = error
                if localError == nil { localError = TealiumCollectError.unknownIssueWithSend }
                self?.didFailToFinish(track,
                                      info: info,
                                      error: localError!)
                return
            }

            // Another message to moduleManager of completed track, this time of
            //  modified track data.
            self?.didFinish(track,
                            info: info)
        })
    }

}
