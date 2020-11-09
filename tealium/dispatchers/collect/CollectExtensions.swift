//
//  CollectExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public extension TealiumConfig {

    /// Overrides the default Collect endpoint URL￼.
    /// NOTE: the Batch URL must be overridden separately. See `overrideCollectBatchURL`.
    /// The full URL must be provided, including protocol and path.
    /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/event  (the path MUST be `/event`).
    /// If using your own custom endpoint, the URL can be any valid URL.
    var overrideCollectURL: String? {
        get {
            options[CollectKey.overrideCollectUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[CollectKey.overrideCollectUrl] = newValue
        }
    }
    
    /// Overrides the default Collect endpoint URL￼.
    /// The full URL must be provided, including protocol and path.
    /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/bulk-event (the path MUST be `/bulk-event`).
    /// If using your own custom endpoint, the URL can be any valid URL. Your endpoint must be prepared to accept batched events in Tealium's proprietary gzipped format.
    var overrideCollectBatchURL: String? {
        get {
            options[CollectKey.overrideCollectBatchUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[CollectKey.overrideCollectBatchUrl] = newValue
        }
    }

    /// Overrides the default Collect endpoint profile￼.
    var overrideCollectProfile: String? {
        get {
            options[CollectKey.overrideCollectProfile] as? String
        }

        set {
            options[CollectKey.overrideCollectProfile] = newValue
        }
    }
    
    /// Overrides the default Collect domain only.
    /// Only the hostname should be provided, excluding the protocol, e.g. `my-company.com`
    var overrideCollectDomain: String? {
        get {
            options[CollectKey.overrideCollectDomain] as? String
        }

        set {
            options[CollectKey.overrideCollectDomain] = newValue
        }
    }
}

public extension Dispatchers {
    static let Collect = CollectModule.self
}
