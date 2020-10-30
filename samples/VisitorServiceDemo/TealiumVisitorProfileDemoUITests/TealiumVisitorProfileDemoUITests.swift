//
//  TealiumVisitorProfileDemoUITests.swift
//  TealiumVisitorProfileDemoUITests
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import XCTest

class TealiumVisitorProfileDemoUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTraceAlertDisplaysAndRespondsToInput() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        XCTAssertNotNil(elementsQuery)
        elementsQuery.collectionViews.cells.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .textField).element.tap()
        elementsQuery.buttons["Start Trace"].tap()
    }
        
    func testLoginNavigatesToAccountScreen() throws {
        
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let groupNameField = app.textFields["Group Name"]
        XCTAssertNotNil(groupNameField)
    }

    func testSeeOffersOpensAlert() throws {
        
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery1 = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery1.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["See your offers!"]/*[[".buttons[\"See your offers!\"].staticTexts[\"See your offers!\"]",".staticTexts[\"See your offers!\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let elementsQuery2 = app.alerts["Offers"].scrollViews.otherElements
        let offersStaticText = elementsQuery2.staticTexts["Offers"]
        XCTAssertNotNil(offersStaticText)
        elementsQuery2.buttons["OK"].tap()
    }
    
    func testClickGamingTabNavigatesToGamingScreen() {
        
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tabBars.buttons["Gaming"].tap()
        
        let virtualCurrencyStaticText = app.staticTexts["Virtual Currency"]
        XCTAssertNotNil(virtualCurrencyStaticText)
        
    }
    
    func testLevelUpIncreasesLevelResponds() {
        
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tabBars.buttons["Gaming"].tap()
        var levelText = app.staticTexts["0"]
        XCTAssertNotNil(levelText)
        XCTAssertTrue(app.steppers.buttons["Increment"].isHittable)
        app.steppers.buttons["Increment"].tap()
        levelText = app.staticTexts["2"]
        XCTAssertNotNil(levelText)
    }
    
    func testClickEcommerceTabNavigatesToEcommerceScreen() {
        
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tabBars.buttons["E-commerce"].tap()
        
        let emailField = app.textFields["Email Address"]
        XCTAssertNotNil(emailField)
    }
    
    func testClickEcommerceTabNavigatesToEcommerceScreenThenTravelScreen() {
        let expect = expectation(description: "Travel tab clickable")
        let app = XCUIApplication()
        app.launch()
        
        
        let elementsQuery = XCUIApplication().alerts["Enter Trace ID"].scrollViews.otherElements
        elementsQuery.buttons["Cancel"].tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Login"]/*[[".buttons[\"Login\"].staticTexts[\"Login\"]",".staticTexts[\"Login\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.tabBars.buttons["E-commerce"].tap()
        
        XCTAssertTrue(app.tabBars.buttons["Travel"].isHittable)
        expect.fulfill()
        wait(for: [expect], timeout: 5.0)
    }
        

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
