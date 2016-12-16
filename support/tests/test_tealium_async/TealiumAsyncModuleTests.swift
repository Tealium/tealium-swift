//
//  TealiumAsyncModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/14/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumAsyncModuleTests: XCTestCase {
    
    var delegateExpectationSuccess : XCTestExpectation?
    var delegateExpectationFail : XCTestExpectation?
    var module : TealiumAsyncModule?
    var queueName: String?
    
    override func setUp() {
        super.setUp()
        
        module = TealiumAsyncModule(delegate: self)
        
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        
        module = nil
        queueName = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEnable() {
        
        delegateExpectationSuccess = self.expectation(description: "asyncEnable")
        
        module?.enable(config: testTealiumConfig)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName == TealiumAsyncKey.queueName, "NOT on expected background queue.")

    }
    
    func testDisable() {
        
        delegateExpectationSuccess = self.expectation(description: "asyncDisable")

        module?.disable()

        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName == TealiumAsyncKey.queueName, "NOT on expected background queue. On: \(currentQueueName())")
    }
    
    func testTrack() {
        
        delegateExpectationSuccess = self.expectation(description: "asyncTrack")

        let tealiumTrack = TealiumTrack(data: [:],
                                        info: [:],
                                        completion: nil)
        module?.track(tealiumTrack)
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName == TealiumAsyncKey.queueName, "NOT on expected background queue.")
        
    }
    
    func testSetQueue() {
        
        let testQueueName = "test.test.test"
        let dispatchQueue = DispatchQueue(label: testQueueName)
        
        module?.setDispatchQueue(queue: dispatchQueue)
        
        delegateExpectationSuccess = self.expectation(description: "asyncSetQueue")
        
        module?.enable(config: testTealiumConfig)

        self.waitForExpectations(timeout: 1.0, handler: nil)
        
        XCTAssertTrue(queueName != TealiumAsyncKey.queueName, "Unexpectedly on Tealium background queue.")

        XCTAssertTrue(queueName == testQueueName, "NOT on the Test queue.")
    }
    
}

func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}

extension TealiumAsyncModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        delegateExpectationSuccess?.fulfill()
        
        queueName = currentQueueName()
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {

        delegateExpectationSuccess?.fulfill()

        queueName = currentQueueName()

    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
   
        delegateExpectationSuccess?.fulfill()

        queueName = currentQueueName()

    }
    
}
