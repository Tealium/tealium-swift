//
//  TealiumCookieProvider.swift
//  tealium-swift
//
//  Created by Craig Rouse on 2/5/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

/// allows overriding default cookie store for unit testing
public protocol TealiumCookieProvider {
    static var shared: TealiumCookieProvider { get }
    var cookies: [HTTPCookie]? { get }
}

/// allows overriding default cookie store for unit testing
public class TealiumHTTPCookieStorage: TealiumCookieProvider {
    public static var shared: TealiumCookieProvider = TealiumHTTPCookieStorage()

    private var httpCookieStorage = HTTPCookieStorage.shared

    public var cookies: [HTTPCookie]? {
        return httpCookieStorage.cookies
    }

    private init() {

    }
}
