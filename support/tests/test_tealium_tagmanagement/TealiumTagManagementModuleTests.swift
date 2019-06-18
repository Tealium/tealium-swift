//
//  TealiumTagManagementModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import Tealium
import XCTest

class TealiumTagManagementModuleTests: XCTestCase {

    var delegateExpectationSuccess: XCTestExpectation?
    var delegateExpectationFail: XCTestExpectation?
    var module: TealiumTagManagementModule?
    var queueName: String?

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
        let module = TealiumTagManagementModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in

            expectation.fulfill()
            XCTAssertTrue(success, "Not all protocols returned. Failing protocols: \(failingProtocols)")

        }

        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

}

func currentQueueName() -> String? {
    let name = __dispatch_queue_get_label(nil)
    return String(cString: name, encoding: .utf8)
}

extension TealiumTagManagementModuleTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        queueName = currentQueueName()
    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        queueName = currentQueueName()
    }

    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumRequest) {
        delegateExpectationSuccess?.fulfill()

        queueName = currentQueueName()
    }

}
