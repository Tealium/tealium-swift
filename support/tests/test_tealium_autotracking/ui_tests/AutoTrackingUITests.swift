//
//  AutoTrackingUITests.swift
//  AutoTrackingUITests
//
//  Created by Enrico Zannini on 10/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest

class AutoTrackingUITests: XCTestCase {

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
        let exp = expectation(description: "Dispatch")
        var text = """
            ContentView
            Root View 0
            
            """
        let textElement = app.staticTexts.element(boundBy: 1)
        XCTAssertEqual(textElement.label, text)
        app.buttons.firstMatch.tap()
        text += "ViewControllerWrapper\n"
        XCTAssertEqual(textElement.label, text)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            text += "RealViewController\n" // Did appear happens late
            XCTAssertEqual(textElement.label, text)
            app.navigationBars.firstMatch.buttons.firstMatch.tap()
            text += "Root View 1\n"
            XCTAssertEqual(textElement.label, text)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
