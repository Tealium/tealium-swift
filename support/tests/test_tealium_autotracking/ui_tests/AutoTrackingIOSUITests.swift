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
        var text = """
            RootView0
            
            """
        assertStaticTextExists(app: app, text: text)
        app.buttons["Launch ViewController"].tap()
        text += "ViewControllerWrapper\n"
        text += "RealVC\n" // Did appear happens late
        assertStaticTextExists(app: app, text: text)
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        text += "RootView1\n"
        assertStaticTextExists(app: app, text: text)
        app.buttons["Launch Second View"].tap()
        text += "SecondView\n"
        assertStaticTextExists(app: app, text: text)
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        text += "RootView2\n"
        assertStaticTextExists(app: app, text: text)
        app.buttons["Launch Third View"].tap()
        text += "AutotrackingView\n"
        assertStaticTextExists(app: app, text: text)
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        text += "RootView3\n"
        assertStaticTextExists(app: app, text: text)
        app.buttons["Launch Default UIViewController"].tap()
        text += "UI\n"
        assertStaticTextExists(app: app, text: text)
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        text += "RootView4\n"
        assertStaticTextExists(app: app, text: text)
    }
    
    func assertStaticTextExists(app: XCUIApplication, text: String) {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Can not find \(text.split(separator: "\n").last!)")
    }
}
