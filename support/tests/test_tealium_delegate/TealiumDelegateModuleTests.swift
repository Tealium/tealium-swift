//
//  TealiumDelegateModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 2/13/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumDelegateModuleTests: XCTestCase {

    var module: TealiumDelegateModule?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMinimumProtocolsReturn() {
        let expectation = self.expectation(description: "minimumProtocolsReturned")
        let helper = TestTealiumHelper()
        let module = TealiumDelegateModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    // Bit of a clunky test
    func testAddAndRemoveMultipleDelegates() {
        // Spin up test module
        module = TealiumDelegateModule(delegate: self)
        let config = TealiumConfig(account: "test",
                                   profile: "test",
                                   environment: "test",
                                   optionalData: nil)
        module!.enable(TealiumEnableRequest(config: config, enableCompletion: nil))

        // Create an array of delegate objects
        let numberOfDelegates = 100
        var arrayOfDelegates = [TestTealiumDelegate]()
        for _ in 0..<numberOfDelegates {
            let newDelegate = TestTealiumDelegate()
            arrayOfDelegates.append(newDelegate)
            module!.delegates?.add(delegate: newDelegate)
        }

        // Run a track call through the module
        let track = TealiumTrackRequest(data: ["key": "value"],
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

extension TealiumDelegateModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule,
                               process: TealiumRequest) {
        // Simulate Module manager passing HandleReport call to delegateModule
        if let request = process as? TealiumTrackRequest {
            self.module!.delegates?.invokeTrackCompleted(forTrackProcess: request)
        }

    }

    func tealiumModuleRequests(module: TealiumModule?,
                               process: TealiumRequest) {

    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule,
                                     module: TealiumModule,
                                     process: TealiumRequest) {

    }

}

class TestTealiumDelegate: TealiumDelegate {

    var shouldTrack = false
    var trackComplete = false

    func reset() {
        shouldTrack = false
        trackComplete = false
    }

    func tealiumShouldTrack(data: [String: Any]) -> Bool {
        shouldTrack = true
        return true
    }

    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?) {
        trackComplete = true
    }

}
