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
    var collectOverrideURL: String? {
        get {
            options[CollectKey.overrideCollectUrl] as? String
        }

        set {
            guard let newValue = newValue else {
                return
            }
            if newValue.contains("vdata") {
                var urlString = newValue
                var lastChar: Character?
                lastChar = urlString.last

                if lastChar != "&" {
                    urlString += "&"
                }
                options[CollectKey.overrideCollectUrl] = urlString
            } else {
                options[CollectKey.overrideCollectUrl] = newValue
            }
        }
    }

    /// Overrides the default Collect endpoint profile￼.
    var collectOverrideProfile: String? {
        get {
            options[CollectKey.overrideCollectProfile] as? String
        }

        set {
            options[CollectKey.overrideCollectProfile] = newValue
        }
    }
}

public extension Dispatchers {
    static let Collect = CollectModule.self
}
