//
//  TealiumTagManagementWKWebViewCookieStoreObserver.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/8/2018
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
import WebKit

@available(iOS 11.0, *)
extension TealiumTagManagementWKWebView: WKHTTPCookieStoreObserver {

    /// Listens for cookie changes in WKHTTPCookieStore
    ///￼  NOTE: this exists purely to work around an issue where cookies are not properly synced to WKWebView instances
    ///
    /// - Parameter cookieStore: `WKHTTPCookieStore` instance
    public func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        DispatchQueue.main.async {
            cookieStore.getAllCookies { _ in
                // no action necessary; retrieving the cookies forces them to sync
            }
        }
    }
}
