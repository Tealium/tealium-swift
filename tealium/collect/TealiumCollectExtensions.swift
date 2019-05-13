//
//  TealiumCollectExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public extension TealiumConfig {

    /// Overrides the default Collect endpoint URL
    ///
    /// - Parameter string: String representing the URL to which all Collect module dispatches should be sent
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

    /// Overrides the default Collect endpoint profile
    ///
    /// - Parameter profile: String containing the name of the Tealium profile to which all Collect module dispatches should be sent
    func setCollectOverrideProfile(profile: String) {
        optionalData[TealiumCollectKey.overrideCollectProfile] = profile
    }

    /// Enables the legacy "vdata" dispatch method
    ///
    /// - Parameter shouldUseLegacyDispatch: Bool (true if vdata should be used)
    func setLegacyDispatchMethod(_ shouldUseLegacyDispatch: Bool) {
        optionalData[TealiumCollectKey.legacyDispatchMethod] = shouldUseLegacyDispatch
    }
}

public extension Tealium {

    /// - Returns: An instance of a TealiumCollectProtocol
    func collect() -> TealiumCollectProtocol? {
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }

        return collectModule.collect
    }
}
