//
//  TealiumCollectConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum TealiumCollectKey {
    static let moduleName = "collect"
    static let encodedURLString = "encoded_url"
    static let overrideCollectUrl = "tealium_override_collect_url"
    static let overrideCollectProfile = "tealium_override_collect_profile"
    static let payload = "payload"
    static let responseHeader = "response_headers"
    public static let errorHeaderKey = "X-Error"
    public static let legacyDispatchMethod = "legacy_dispatch_method"
}
