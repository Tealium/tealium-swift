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

    var disposeBag = TealiumDisposeBag()
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
        disposeBag = TealiumDisposeBag()
        super.tearDown()
    }

    func testRequestEventTrack() {
        let module = self.module

        expectationRequest = expectation(description: "emptyEventDetected")

        let viewName = "RequestEventTrackView"
        module.requestViewTrack(viewName: viewName)

        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(viewName, currentViewName)
    }

    func testAddCustomData() {
        let module = self.module

        expectationRequest = expectation(description: "customDataRequest1")
        let name = addDataViewName+"1"
        module.requestViewTrack(viewName: name)

        waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(name, currentViewName)
    }

    // Cannot unit test swizzling/SwiftUI
    
    func testRequestEventTrackToInstanceManager() {
        let config = testTealiumConfig.copy
        config.collectors = [Collectors.AutoTracking]
        config.autoTrackingCollectorDelegate = self
        let teal = Tealium(config: config)
        expectationRequest = expectation(description: "emptyEventToManagerDetected")

        let viewName = "RequestEventTrackToInstanceManagerView"
        AutotrackingModule.autoTrackView(viewName: viewName)
        
        waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(viewName, currentViewName)
        teal.zz_internal_modulesManager?.collectors = []
    }
    
    func testAddCustomDataToInstanceManager() {
        expectationRequest = expectation(description: "customDataRequest2")

        let config = testTealiumConfig.copy
        config.collectors = [Collectors.AutoTracking]
        config.autoTrackingCollectorDelegate = self
        let teal = Tealium(config: config)
        let name = self.addDataViewName+"2"
        AutotrackingModule.autoTrackView(viewName: name)
        

        waitForExpectations(timeout: 4.0, handler: nil)

        XCTAssertEqual(name, currentViewName)
        teal.zz_internal_modulesManager?.collectors = []
    }
    
    func testView() {
        let viewName = "testView"
        
        let firstReceiveExp = expectation(description: "Will receive view")
        let secondReceiveExp = expectation(description: "Will NOT receive view")
        secondReceiveExp.isInverted = true
        AutotrackingModule.autoTrackView(viewName: viewName)
        AutotrackingModule.onAutoTrackView.subscribe { name in
            if name == viewName {
                firstReceiveExp.fulfill()
            } else {
                secondReceiveExp.fulfill()
            }
        }.toDisposeBag(disposeBag)
        
        AutotrackingModule.onAutoTrackView.subscribe { name in
            secondReceiveExp.fulfill()
        }.toDisposeBag(disposeBag)
        wait(for: [firstReceiveExp, secondReceiveExp], timeout: 0)
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
        if screenName.starts(with: addDataViewName) {
            return addDataDictionary
        }
        return [:]
    }
}

class TestObject: NSObject {

}
