//
//  TagManagementWKWebViewCookieMigrator.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import WebKit
#if tagmanagement
import TealiumCore
#endif

// MARK: Cookie migration from HTTPCookieStore/UIWebView
extension TagManagementWKWebView {

    /// Migrates cookies from HTTPCookieStore to a specified WKWebView instance
    ///
    /// - Parameters:
    ///     - webView: A valid `WKWebView` instance
    ///     - userDefaults: An instance of `UserDefaults` to support dependency injection for unit testing
    ///     - completion: Completion block to be called when cookies have been migrated
    func migrateCookies(forWebView webView: WKWebView,
                        withCookieProvider cookieProvider: TealiumCookieProvider = TealiumHTTPCookieStorage.shared,
                        userDefaults: UserDefaults? = UserDefaults.standard,
                        _ completion: @escaping () -> Void) {

        guard !self.getHasMigrated(userDefaults: userDefaults) else {
            completion()
            return
        }

        let dispatchGroup = DispatchGroup()
        guard let allCookies = cookieProvider.cookies else {
            return
        }

        allCookies.forEach { cookie in
            if #available(iOS 11.0, *) {
                dispatchGroup.enter()
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.setHasMigrated(userDefaults: userDefaults)
            completion()
        }
    }

    /// Setter to store a flag in `UserDefaults` to indicate that cookies have been migrated
    ///
    /// - Parameter userDefaults: An instance of `UserDefaults` to support dependency injection for unit testing
    func setHasMigrated(userDefaults: UserDefaults? = UserDefaults.standard) {
        userDefaults?.set(true, forKey: "com.tealium.tagmanagement.cookiesMigrated")
    }

    /// Getter to check `UserDefaults` and see if cookies have already been migrated
    ///
    /// - Parameter userDefaults: An instance of `UserDefaults` to support dependency injection for unit testing
    func getHasMigrated(userDefaults: UserDefaults? = UserDefaults.standard) -> Bool {
        return userDefaults?.bool(forKey: "com.tealium.tagmanagement.cookiesMigrated") ?? false
    }
}
#endif
