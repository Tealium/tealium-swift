//
//  AutotrackingModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumAutotracking
@testable import TealiumCore
import XCTest

class AutotrackingModuleTests: XCTestCase {
    
    

    var module: AutotrackingModule {
        let config = testTealiumConfig.copy
        config.autoTrackingCollectorDelegate = self
        let context = TestTealiumHelper.context(with: config)
        return AutotrackingModule(context: context, delegate: self, diskStorage: nil) { _ in

        }
    }
    var expectationRequest: XCTestExpectation?
    var expectationShouldTrack: XCTestExpectation?
    var expectationDidComplete: XCTestExpectation?
    
    var currentViewName = ""

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        expectationRequest = nil
        expectationDidComplete = nil
        expectationShouldTrack = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRequestEventTrack() {
        let module = self.module

        expectationRequest = expectation(description: "emptyEventDetected")

        let viewName = "someView"
        module.requestViewTrack(viewName: viewName)

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(viewName, currentViewName)
    }

    func testAddCustomData() {
        let module = self.module

        expectationRequest = expectation(description: "customDataRequest")

        module.requestViewTrack(viewName: addDataViewName)

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(addDataViewName, currentViewName)
    }

    // Cannot unit test swizzling/SwiftUI
    
    // TODO: Add tests for tealiumInstance autotracking events called

}

extension AutotrackingModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {
    }

    func requestDequeue(reason: String) {

    }
}

extension AutotrackingModuleTests: AutoTrackingDelegate {
    var addDataViewName: String {
        "addData"
    }
    var addDataDictionary: [String: Any] {
        ["someKey":"someValue"]
    }
    func onCollectScreenView(screenName: String) -> [String : Any] {
        self.currentViewName = screenName
        expectationRequest?.fulfill()
        if screenName == addDataViewName {
            return addDataDictionary
        }
        return [:]
    }
}

class TestObject: NSObject {

}
