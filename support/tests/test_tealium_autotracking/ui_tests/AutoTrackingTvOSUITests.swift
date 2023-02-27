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
        assertStaticTextExists(app: app, text: "RootView0")
        remote.press(.select)
        assertStaticTextExists(app: app, text: "ViewControllerWrapper")
        assertStaticTextExists(app: app, text: "RealVC") // Did appear happens late
        remote.press(.menu)
        assertStaticTextExists(app: app, text: "RootView1")
        remote.press(.down)
        remote.press(.select)
        assertStaticTextExists(app: app, text: "SecondView")
        remote.press(.menu)
        assertStaticTextExists(app: app, text: "RootView2")
        remote.press(.down)
        remote.press(.select)
        assertStaticTextExists(app: app, text: "AutotrackingView")
        remote.press(.menu)
        assertStaticTextExists(app: app, text: "RootView3")
        remote.press(.down)
        remote.press(.select)
        assertStaticTextExists(app: app, text: "UI")
    }

    func assertStaticTextExists(app: XCUIApplication, text: String) {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", text) // don't know why value doesn't work here
        XCTAssertTrue(app.staticTexts
            .containing(predicate).firstMatch
            .waitForExistence(timeout: 5),
                      "Can not find \(text)")
    }
}
