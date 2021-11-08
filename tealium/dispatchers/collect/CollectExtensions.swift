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

extension TealiumConfigKey {
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let overrideCollectBatchUrl = "tealium_override_collect_batch_url"
    static let overrideCollectProfile = "tealium_override_collect_profile"
    static let overrideCollectDomain = "tealium_override_collect_domain"
}

public extension TealiumConfig {

    /// Overrides the default Collect endpoint URL￼.
    /// NOTE: the Batch URL must be overridden separately. See `overrideCollectBatchURL`.
    /// The full URL must be provided, including protocol and path.
    /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/event  (the path MUST be `/event`).
    /// If using your own custom endpoint, the URL can be any valid URL.
    var overrideCollectURL: String? {
        get {
            options[TealiumConfigKey.overrideCollectUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumConfigKey.overrideCollectUrl] = newValue
        }
    }
    
    /// Overrides the default Collect endpoint URL￼.
    /// The full URL must be provided, including protocol and path.
    /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/bulk-event (the path MUST be `/bulk-event`).
    /// If using your own custom endpoint, the URL can be any valid URL. Your endpoint must be prepared to accept batched events in Tealium's proprietary gzipped format.
    var overrideCollectBatchURL: String? {
        get {
            options[TealiumConfigKey.overrideCollectBatchUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            options[TealiumConfigKey.overrideCollectBatchUrl] = newValue
        }
    }

    /// Overrides the default Collect endpoint profile￼.
    var overrideCollectProfile: String? {
        get {
            options[TealiumConfigKey.overrideCollectProfile] as? String
        }

        set {
            options[TealiumConfigKey.overrideCollectProfile] = newValue
        }
    }
    
    /// Overrides the default Collect domain only.
    /// Only the hostname should be provided, excluding the protocol, e.g. `my-company.com`
    var overrideCollectDomain: String? {
        get {
            options[TealiumConfigKey.overrideCollectDomain] as? String
        }

        set {
            options[TealiumConfigKey.overrideCollectDomain] = newValue
        }
    }
}

public extension Dispatchers {
    static let Collect = CollectModule.self
}
