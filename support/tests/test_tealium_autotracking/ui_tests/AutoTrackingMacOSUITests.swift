//
//  AutoTrackingIOSUITests.swift
//  AutoTrackingIOSUITests
//
//  Created by Enrico Zannini on 10/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest

class AutoTrackingMacOSUITests: XCTestCase {

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
        app.buttons["Launch ViewController"].click()
        app.assertStaticTextExists(text: "SomeView")
        app.buttons["Launch Second View"].click()
        app.assertStaticTextExists(text: "SecondView")
        app.buttons["Launch ViewController"].click()
        app.assertStaticTextExists(text: "SomeView")
        app.buttons["Launch Third View"].click()
        app.assertStaticTextExists(text: "AutotrackingView")
    }
}
