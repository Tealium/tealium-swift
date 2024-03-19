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
    let delegate = AutotrackingTestDelegate()
    var module: AutotrackingModule {
        let config = testTealiumConfig.copy
        config.autoTrackingCollectorDelegate = delegate
        config.autoTrackingBlocklistFilename = "blocklist"
        let context = TestTealiumHelper.context(with: config)
        let module = AutotrackingModule(context: context, delegate: self, diskStorage: nil, blockListBundle: Bundle(for: AutotrackingModuleTests.self)) { _ in

        }
        return module
    }
    
    var disposeBag = TealiumDisposeBag()
    
    func waitOnTealiumSerialQueue(_ block: () -> ()) {
        TealiumQueues.backgroundSerialQueue.sync {
            block()
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        TealiumInstanceManager.shared.disable()
        disposeBag = TealiumDisposeBag()
        super.tearDown()
    }

    func testRequestEventTrack() {
        let module = self.module

        let emptyEventReceived = expectation(description: "Empty event received")

        let viewName = "RequestEventTrackView"
        delegate._onCollectScreenView = { screenName in
            XCTAssertEqual(screenName, viewName)
            emptyEventReceived.fulfill()
            return [:]
        }
        module.requestViewTrack(viewName: viewName)
        
        waitOnTealiumSerialQueue {
            waitForExpectations(timeout: 1.0)
        }
    }

    // Cannot unit test swizzling/SwiftUI
    
    func testRequestEventTrackToInstanceManager() {
        let config = testTealiumConfig.copy
        config.collectors = [Collectors.AutoTracking]
        config.autoTrackingCollectorDelegate = delegate
        let tealiumInitialized = expectation(description: "Tealium initialized")
        let teal = Tealium(config: config) { _ in
            tealiumInitialized.fulfill()
        }

        let viewName = "RequestEventTrackToInstanceManagerView"
        
        let eventToManagerReceived = expectation(description: "emptyEventToManagerDetected")
        delegate._onCollectScreenView = { screenName in
            XCTAssertEqual(screenName, viewName)
            eventToManagerReceived.fulfill()
            return [:]
        }
        AutotrackingModule.autoTrackView(viewName: viewName)
        
        waitOnTealiumSerialQueue {
            wait(for: [tealiumInitialized], timeout: 1.0)
        }
        waitOnTealiumSerialQueue {
            wait(for: [eventToManagerReceived], timeout: 1.0)
        }
        teal.zz_internal_modulesManager?.collectors = []
    }

    func testAutotrackingBufferEvents() {
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
        wait(for: [firstReceiveExp, secondReceiveExp], timeout: 4.0)
    }
    
    func testBlockedViewsAreDiscarded() {
        let viewName = "testView"
        let blockedViewName = "blocked"
        
        let module = self.module

        let trackedUnblockedViews = expectation(description: "Only track unblocked views")
        
        delegate._onCollectScreenView = { screenName in
            XCTAssertEqual(screenName, viewName)
            trackedUnblockedViews.fulfill()
            return [:]
        }
        
        module.requestViewTrack(viewName: viewName)
        module.requestViewTrack(viewName: blockedViewName)

        waitOnTealiumSerialQueue {
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func testBlockedViewsAreCaseInsensitiveAndCheckForContains() {
        let blockedViewName1 = "BlOckEd"
        let blockedViewName2 = "UNBlOckEd"
        let blockedViewName3 = "BlOckEdView"
        
        let module = self.module

        let blockedViewsAreNotTracked = expectation(description: "Blocked views are not tracked")
        blockedViewsAreNotTracked.isInverted = true
        delegate._onCollectScreenView = { screenName in
            blockedViewsAreNotTracked.fulfill()
            return [:]
        }
        
        module.requestViewTrack(viewName: blockedViewName1)
        module.requestViewTrack(viewName: blockedViewName2)
        module.requestViewTrack(viewName: blockedViewName3)

        waitOnTealiumSerialQueue {
            waitForExpectations(timeout: 1.0)
        }
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

class AutotrackingTestDelegate: AutoTrackingDelegate {
    var _onCollectScreenView: (String) -> [String: Any] = { _ in
        [:]
    }
    func onCollectScreenView(screenName: String) -> [String : Any] {
        _onCollectScreenView(screenName)
    }
}
