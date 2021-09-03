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
        TealiumInstanceManager.shared.disable()
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
    
    func testRequestEventTrackToInstanceManager() {
        let config = testTealiumConfig.copy
        config.collectors = [Collectors.AutoTracking]
        config.autoTrackingCollectorDelegate = self
        let _ = Tealium(config: config)
        expectationRequest = expectation(description: "emptyEventDetected")

        let viewName = "someView"
        TealiumInstanceManager.shared.autoTrackView(viewName: viewName)
        
        waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(viewName, currentViewName)
    }
    
    func testAddCustomDataToInstanceManager() {
        expectationRequest = expectation(description: "customDataRequest")

        let config = testTealiumConfig.copy
        config.collectors = [Collectors.AutoTracking]
        config.autoTrackingCollectorDelegate = self
        let _ = Tealium(config: config)
        TealiumInstanceManager.shared.autoTrackView(viewName: self.addDataViewName)
        

        waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(addDataViewName, currentViewName)
    }

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
