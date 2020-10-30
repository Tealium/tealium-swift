//
//  CollectConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public enum CollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let overrideCollectProfile = "tealium_override_collect_profile"
    static let payload = "payload"
    static let responseHeader = "response_headers"
    public static let errorHeaderKey = TealiumKey.errorHeaderKey
}
