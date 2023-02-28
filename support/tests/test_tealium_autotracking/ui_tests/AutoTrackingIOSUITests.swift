//
//  AutoTrackingIOSUITests.swift
//  AutoTrackingIOSUITests
//
//  Created by Enrico Zannini on 10/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest

class AutoTrackingIOSUITests: XCTestCase {

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
        app.assertStaticTextExists(text: "RootView0")
        app.buttons["Launch ViewController"].tap()
        app.assertStaticTextExists(text: "ViewControllerWrapper")
        app.assertStaticTextExists(text: "RealVC") // Did appear happens late
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.assertStaticTextExists(text: "RootView1")
        app.buttons["Launch Second View"].tap()
        app.assertStaticTextExists(text: "SecondView")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.assertStaticTextExists(text: "RootView2")
        app.buttons["Launch Third View"].tap()
        app.assertStaticTextExists(text: "AutotrackingView")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.assertStaticTextExists(text: "RootView3")
        app.buttons["Launch Default UIViewController"].tap()
        app.assertStaticTextExists(text: "UI")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        app.assertStaticTextExists(text: "RootView4")
    }
}
