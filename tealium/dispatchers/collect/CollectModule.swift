//
//  CollectModule.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

/// Dispatch Service Module for sending track data to the Tealium Collect or custom endpoint.
public class CollectModule: Dispatcher {

    public let id: String = ModuleNames.collect
    var collect: CollectProtocol?
    weak var delegate: ModuleDelegate?
    public var config: TealiumConfig

    /// Initializes the module
    ///
    /// - Parameter config: `TealiumConfig` instance
    /// - Parameter delegate: `ModuleDelegate` instance
    /// - Parameter completion: `ModuleCompletion?` block to be called when init is finished
    public required init(context: TealiumContext,
                         delegate: ModuleDelegate,
                         completion: ModuleCompletion?) {

        self.config = context.config
        self.delegate = delegate
        collect = CollectEventDispatcher(config: config, completion: nil)
        completion?((.success(true), nil))
    }

    /// Detects track type and dispatches appropriately, adding mandatory data (account and profile) to the track if missing.￼
    ///
    /// - Parameter track: `TealiumRequest`, which is expected to be either a `TealiumTrackRequest` or a `TealiumBatchTrackRequest`
    /// - Parameter completion: `ModuleCompletion?` block to be called when track is finished
    public func dynamicTrack(_ request: TealiumRequest,
                             completion: ModuleCompletion?) {
        guard collect != nil else {
            completion?((.failure(CollectError.collectNotInitialized), nil))
            return
        }

        switch request {
        case let request as TealiumTrackRequest:
            guard !isConsentEvent(request.trackDictionary) else {
                completion?((.failure(CollectError.trackNotApplicableForCollectModule), nil))
                return
            }
            self.track(prepareForDispatch(request), completion: completion)
        case let request as TealiumBatchTrackRequest:
            var requests = request.trackRequests
            requests = requests.filter {
                !isConsentEvent($0.trackDictionary)
            }.map {
                prepareForDispatch($0)
            }
            guard !requests.isEmpty else {
                completion?((.failure(CollectError.invalidBatchRequest), nil))
                return
            }
            let newRequest = TealiumBatchTrackRequest(trackRequests: requests)
            self.batchTrack(newRequest, completion: completion)
        default:
            completion?((.failure(CollectError.trackNotApplicableForCollectModule), nil))
            return
        }
    }

    /// Checks if the event is intended to set consent cookies in the Tag Management module
    /// - Parameter data: `[String: Any]` containing the data layer for this event
    /// - Returns: `Bool`
    func isConsentEvent(_ data: [String: Any]) -> Bool {
        guard let event = data[TealiumDataKey.event] as? String else {
            return false
        }
        return TealiumKey.updateConsentCookieEventNames.contains(event)
    }

    /// Adds required account information to the dispatch if missing￼.
    ///
    /// - Parameter request: `TealiumTrackRequest` to be insepcted/modified
    /// - Returns: `TealiumTrackRequest`
    func prepareForDispatch(_ request: TealiumTrackRequest) -> TealiumTrackRequest {
        var newTrack = request.trackDictionary
        if newTrack[TealiumDataKey.account] == nil,
           newTrack[TealiumDataKey.profile] == nil {
            newTrack[TealiumDataKey.account] = config.account
            newTrack[TealiumDataKey.profile] = config.profile
        }

        if let profileOverride = config.overrideCollectProfile {
            newTrack[TealiumDataKey.profile] = profileOverride
        }

        newTrack[TealiumDataKey.dispatchService] = CollectKey.moduleName
        return TealiumTrackRequest(data: newTrack)
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumTrackRequest` to be dispatched
    /// - Parameter completion: `ModuleCompletion?` block to be called when track is finished
    func track(_ track: TealiumTrackRequest,
               completion: ModuleCompletion?) {
        guard let collect = collect else {
            completion?((.failure(CollectError.collectNotInitialized), nil))
            return
        }

        // Send the current track call
        let data = track.trackDictionary

        collect.dispatch(data: data, completion: completion)
    }

    /// Adds relevant info to the track request, then passes the request to a dipatcher for processing￼.
    ///
    /// - Parameter track: `TealiumBatchTrackRequest` to be dispatched
    /// - Parameter completion: `ModuleCompletion?` block to be called when track is finished
    func batchTrack(_ request: TealiumBatchTrackRequest,
                    completion: ModuleCompletion?) {
        guard let collect = collect else {
            completion?((.failure(CollectError.collectNotInitialized), nil))
            return
        }

        guard let compressed = request.compressed() else {
            completion?((.failure(CollectError.invalidBatchRequest), nil))
            return
        }

        collect.dispatchBatch(data: compressed, completion: completion)
    }

}
