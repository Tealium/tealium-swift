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
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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

}


class NavigationDelegate: NSObject, WKNavigationDelegate {
    
    
}
