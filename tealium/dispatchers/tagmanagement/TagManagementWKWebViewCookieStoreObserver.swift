//
//  TagManagementWKWebViewCookieStoreObserver.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import WebKit

@available(iOS 11.0, *)
extension TagManagementWKWebView: WKHTTPCookieStoreObserver {

    /// Listens for cookie changes in WKHTTPCookieStore
    ///￼  NOTE: this exists purely to work around an issue where cookies are not properly synced to WKWebView instances
    ///
    /// - Parameter cookieStore: `WKHTTPCookieStore` instance
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        DispatchQueue.main.async {
            cookieStore.getAllCookies { _ in
                // no action necessary; retrieving the cookies forces them to sync
            }
        }
    }
}
#endif
