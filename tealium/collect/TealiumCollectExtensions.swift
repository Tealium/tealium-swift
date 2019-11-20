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

    /// Overrides the default Collect endpoint URL￼.
    ///
    /// - Parameter string: `String` representing the URL to which all Collect module dispatches should be sent
    func setCollectOverrideURL(url: String) {
        if url.contains("vdata") {
            var urlString = url
            var lastChar: Character?
            lastChar = urlString.last

            if lastChar != "&" {
                urlString += "&"
            }
            optionalData[TealiumCollectKey.overrideCollectUrl] = urlString
        } else {
            optionalData[TealiumCollectKey.overrideCollectUrl] = url
        }

    }

    /// Overrides the default Collect endpoint profile￼.
    ///
    /// - Parameter profile: `String` containing the name of the Tealium profile to which all Collect module dispatches should be sent
    func setCollectOverrideProfile(profile: String) {
        optionalData[TealiumCollectKey.overrideCollectProfile] = profile
    }

}

public extension Tealium {

    /// - Returns: An instance of a `TealiumCollectProtocol`
    func collect() -> TealiumCollectProtocol? {
        guard let collectModule = modulesManager.getModule(forName: TealiumCollectKey.moduleName) as? TealiumCollectModule else {
            return nil
        }

        return collectModule.collect
    }
}
