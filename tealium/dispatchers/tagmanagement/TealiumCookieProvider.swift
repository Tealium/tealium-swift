//
//  TealiumCookieProvider.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

/// allows overriding default cookie store for unit testing
protocol TealiumCookieProvider {
    static var shared: TealiumCookieProvider { get }
    var cookies: [HTTPCookie]? { get }
}

/// allows overriding default cookie store for unit testing
class TealiumHTTPCookieStorage: TealiumCookieProvider {
    static var shared: TealiumCookieProvider = TealiumHTTPCookieStorage()

    private var httpCookieStorage = HTTPCookieStorage.shared

    var cookies: [HTTPCookie]? {
        return httpCookieStorage.cookies
    }

    private init() {

    }
}
#else
#endif
