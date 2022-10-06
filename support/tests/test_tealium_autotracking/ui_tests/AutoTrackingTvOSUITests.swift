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
        var text = findStartText(app:app)
        assertStaticTextExists(app: app, text: text)
        remote.press(.select)
        text += "ViewControllerWrapper\n"
        text += "RealVC\n" // Did appear happens late
        assertStaticTextExists(app: app, text: text)
        remote.press(.menu)
        text += "RootView1\n"
        assertStaticTextExists(app: app, text: text)
        remote.press(.down)
        remote.press(.select)
        text += "SecondView\n"
        assertStaticTextExists(app: app, text: text)
        remote.press(.menu)
        text += "RootView2\n"
        assertStaticTextExists(app: app, text: text)
        remote.press(.down)
        remote.press(.select)
        text += "AutotrackingView\n"
        assertStaticTextExists(app: app, text: text)
        remote.press(.menu)
        text += "RootView3\n"
        assertStaticTextExists(app: app, text: text)
        remote.press(.down)
        remote.press(.select)
        text += "UI\n"
        assertStaticTextExists(app: app, text: text)
    }
    // Sometimes UINavigationController is after RootView0
    func findStartText(app: XCUIApplication) -> String {
        let text = """
            RootView0
            UINavigationController
            
            """
        if app.staticTexts[text].waitForExistence(timeout: 5) {
            return text
        }
        let otherText = """
            UINavigationController
            RootView0
            
            """
        if app.staticTexts[otherText].waitForExistence(timeout: 5) {
            return otherText
        }
        return app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS 'RootView0'"))
            .element(matching: .any, identifier: nil)
            .label // Last attempt
    }
    
    func assertStaticTextExists(app: XCUIApplication, text: String) {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Can not find \(text.split(separator: "\n").last!)")
    }
}
