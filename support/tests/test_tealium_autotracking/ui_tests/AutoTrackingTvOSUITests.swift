//
//  AutoTrackingTvOSUITests.swift
//  AutoTrackingTvOSUITests
//
//  Created by Enrico Zannini on 15/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest

class AutoTrackingTvOSUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAutotrackingApp() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        let remote = XCUIRemote.shared
        app.assertStaticTextExists(text: "RootView0")
        remote.press(.select)
        app.assertStaticTextExists(text: "ViewControllerWrapper")
        app.assertStaticTextExists(text: "RealVC") // Did appear happens late
        remote.press(.menu)
        app.assertStaticTextExists(text: "RootView1")
        remote.press(.down)
        remote.press(.select)
        app.assertStaticTextExists(text: "SecondView")
        remote.press(.menu)
        app.assertStaticTextExists(text: "RootView2")
        remote.press(.down)
        remote.press(.select)
        app.assertStaticTextExists(text: "AutotrackingView")
        remote.press(.menu)
        app.assertStaticTextExists(text: "RootView3")
        remote.press(.down)
        remote.press(.select)
        app.assertStaticTextExists(text: "UI")
    }
}
