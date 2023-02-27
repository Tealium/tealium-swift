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
        assertStaticTextExists(app: app, text: "RootView0")
        app.buttons["Launch ViewController"].click()
        assertStaticTextExists(app: app, text: "SomeView")
        app.buttons["Launch Second View"].click()
        assertStaticTextExists(app: app, text: "SecondView")
        app.buttons["Launch ViewController"].click()
        assertStaticTextExists(app: app, text: "SomeView")
        app.buttons["Launch Third View"].click()
        assertStaticTextExists(app: app, text: "AutotrackingView")
    }
    
    func assertStaticTextExists(app: XCUIApplication, text: String) {
        let predicate = NSPredicate(format: "value CONTAINS[c] %@", text) // don't know why label doesn't work here
        XCTAssertTrue(app.staticTexts
            .containing(predicate).firstMatch
            .waitForExistence(timeout: 5),
                      "Can not find \(text)")
    }
}
