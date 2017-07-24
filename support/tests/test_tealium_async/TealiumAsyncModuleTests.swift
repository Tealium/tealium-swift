//
//  TealiumAsyncModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumAsyncModuleTests: XCTestCase {
    
    var delegateEnableExpectationSuccess : XCTestExpectation?
    var delegateTrackExpectationSuccess : XCTestExpectation?
    var delegateDisableExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail : XCTestExpectation?
    var module : TealiumAsyncModule?
    var queueName: String?
    var expectedQueueName : String?
    
    let appleBackgroundQueueName = "com.apple.root.background-qos"
    let appleMainThread = "com.apple.main-thread"
    
    override func setUp() {
        super.setUp()
        
        module = TealiumAsyncModule(delegate: self)
        expectedQueueName = appleBackgroundQueueName
//        expectedQueueName = TealiumAsyncKey.queueName
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        
        module = nil
        queueName = nil
        delegateExpectationFail = nil
        delegateEnableExpectationSuccess = nil
        delegateTrackExpectationSuccess = nil
        delegateDisableExpectationSuccess = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Not realiable due to thread routing
//    func testMinimumProtocolsReturn() {
//        
//        let expectation = self.expectation(description: "minimumProtocolsReturned")
//        let helper = test_tealium_helper()
//        let module = TealiumAsyncModule(delegate: nil)
//        
//        let queueName = currentQueueName()
//        
//        
//        module.setDispatchQueue(queue: DispatchQueue.main)
//        
//        helper.modulesReturnsMinimumProtocols(module: module) { (success, failingProtocols) in
//            
//            expectation.fulfill()
//            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")
//            
//        }
//        
//        self.waitForExpectations(timeout: 1.0, handler: nil)
//        
//    }
    
    func testEnable() {
        
        delegateEnableExpectationSuccess = self.expectation(description: "asyncEnable")
        
        module?.enable(testEnableRequest)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertTrue(queueName == expectedQueueName, "NOT on expected background queue.")

    }

    func testDisable() {
        
        delegateDisableExpectationSuccess = self.expectation(description: "asyncDisable")

        module?.disable(testDisableRequest)

        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        // Disabled - so should not be on background queue anymore
        XCTAssertTrue(queueName == expectedQueueName, "NOT on expected background queue. On: \(String(describing: currentQueueName()))")
    }
    
    func testTrack() {
        
        delegateTrackExpectationSuccess = self.expectation(description: "asyncTrack")

        module?.handle(testTrackRequest)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName == expectedQueueName, "NOT on expected background queue.")
        
    }
    
    func testSetQueue() {
        
        let testQueueName = "test.test.test"
        let dispatchQueue = DispatchQueue(label: testQueueName)
        
        module?.setDispatchQueue(queue: dispatchQueue)
        
        delegateEnableExpectationSuccess = self.expectation(description: "asyncSetQueue")
        
        module?.enable(TealiumEnableRequest(config: testTealiumConfig))

        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName != expectedQueueName, "Unexpectedly on Tealium background queue.")

        XCTAssertTrue(queueName == testQueueName, "NOT on the Test queue.")
    }
    
}

func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}

extension TealiumAsyncModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        
        queueName = currentQueueName()

        if process is TealiumEnableRequest {
            delegateEnableExpectationSuccess?.fulfill()
        }
        
        if process is TealiumTrackRequest {
            delegateTrackExpectationSuccess?.fulfill()
        }
    
        if process is TealiumDisableRequest {
            delegateDisableExpectationSuccess?.fulfill()
        }

    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumRequest) {

//        delegateExpectationSuccess?.fulfill()
//
//        queueName = currentQueueName()

    }

    
}
