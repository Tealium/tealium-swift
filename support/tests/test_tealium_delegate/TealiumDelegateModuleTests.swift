//
//  TealiumDelegateModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/13/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import XCTest

class TealiumDelegateModuleTests: XCTestCase {
    
    var module : TealiumDelegateModule?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMinimumProtocolsReturn() {
        
        let helper = test_tealium_helper()
        let module = TealiumDelegateModule(delegate: nil)
        let tuple = helper.modulesReturnsMinimumProtocols(module: module)
        XCTAssertTrue(tuple.success, "Not all protocols returned. Failing protocols: \(tuple.protocolsFailing)")
        
    }
    
    // Bit of a clunky test
    func testAddAndRemoveMultipleDelegates() {
        
        // Spin up test module
        module = TealiumDelegateModule(delegate:self)
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   optionalData: nil)
        module!.enable(config: config)
        
        // Create an array of delegate objects
        let numberOfDelegates = 100
        var arrayOfDelegates = [TestTealiumDelegate]()
        for _ in 0..<numberOfDelegates {
            let newDelegate = TestTealiumDelegate()
            arrayOfDelegates.append(newDelegate)
            module!.delegates?.add(delegate: newDelegate)
        }
        
        // Run a track call through the module
        let track = TealiumTrack(data: ["key":"value"],
                                 info: ["infoKey":"infoValue"],
                                 completion: nil)
        module!.track(track)
        
        // Check array
        XCTAssertTrue(arrayOfDelegates.count == numberOfDelegates)
        
        for delegate in arrayOfDelegates {
            XCTAssertTrue(delegate.shouldTrack)
            XCTAssertTrue(delegate.trackComplete)
        }
        
        // Remove a random number of delegates
        let numberToRemove = arc4random_uniform(UInt32(numberOfDelegates))  // Up to 1 remaining
        for _ in 0..<numberToRemove {
            arrayOfDelegates.removeLast()
        }
        let newNumber = numberOfDelegates - Int(numberToRemove)
        
        // Reset delegates
        for delegate in arrayOfDelegates {
            delegate.reset()
        }
        module!.track(track)
        
        // Check array again
        XCTAssertTrue(arrayOfDelegates.count == newNumber, "Array expected count of \(newNumber) different from found: \(arrayOfDelegates.count)" )
        
        for delegate in arrayOfDelegates {
            XCTAssertTrue(delegate.shouldTrack)
            XCTAssertTrue(delegate.trackComplete)
        }
        
    }
    
}

extension TealiumDelegateModuleTests : TealiumModuleDelegate {
    
    func tealiumModuleFinished(module: TealiumModule,
                               process: TealiumProcess) {
        
        // Simulate Module manager passing HandleReport call to delegateModule
        self.module!.delegates?.invokeTrackCompleted(forTrackProcess: process)
        
    }
    
    func tealiumModuleRequests(module: TealiumModule,
                               process: TealiumProcess) {
        
    }
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule,
                                     module: TealiumModule,
                                     process: TealiumProcess) {
        
    }
    
}

class TestTealiumDelegate : TealiumDelegate {
    
    var shouldTrack = false
    var trackComplete = false
    
    func reset() {
        shouldTrack = false
        trackComplete = false
    }
    
    func tealiumShouldTrack(data: [String : Any]) -> Bool {
        shouldTrack = true
        return true
    }
    
    func tealiumTrackCompleted(success: Bool, info: [String : Any]?, error: Error?) {
        trackComplete = true
    }
    
}
