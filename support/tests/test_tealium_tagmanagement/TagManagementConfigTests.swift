//
//  TagManagementConfigTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
import WebKit
@testable import TealiumCore
@testable import TealiumTagManagement

class TagManagementConfigTests: XCTestCase {

    func testWeakDelegate() throws {
        let config = TealiumConfig(account: "", profile: "", environment: "")
        var delegate: NavigationDelegate? = NavigationDelegate()
        config.webViewDelegates = [delegate!]
        XCTAssertNotNil(config.webViewDelegates)
        XCTAssertEqual(config.webViewDelegates!.count, 1)
        XCTAssertTrue(config.webViewDelegates![0] is NavigationDelegate)
        delegate = nil
        XCTAssertEqual(config.webViewDelegates!.count, 0)
    }

    func testWebviewUrlIsWellConstructed() {
        let config = TealiumConfig(account: "account", profile: "profile", environment: "environment")
        XCTAssertEqual(config.webviewURL?.absoluteString, "https://tags.tiqcdn.com/utag/account/profile/environment/mobile.html?sdk_session_count=true")
    }

}


class NavigationDelegate: NSObject, WKNavigationDelegate {
    
    
}
