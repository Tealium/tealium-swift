//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/6/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumCollectPostDispatcherTests: XCTestCase {

    let testJSONString = """
                            {\n  \"tealium_account\" : \"hello\",\n  \"tealium_environment\" : \"dev\",\n  \"tealium_profile\" : \"tester\"\n}
                            """
    let testDictionary = ["tealium_account": "hello",
                      "tealium_environment": "dev",
                      "tealium_profile": "tester"
    ]
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSendURLRequest() {
        let waiter = XCTWaiter(delegate: nil)
        let expectation = XCTestExpectation(description: "successful dispatch")
        if let request = urlPOSTRequestWithJSONString(testJSONString, dispatchURL: TealiumCollectPostDispatcher.defaultDispatchURL) {
            _ = TealiumCollectPostDispatcher(dispatchURL: TealiumCollectPostDispatcher.defaultDispatchURL) { dispatcher in
                dispatcher?.sendURLRequest(request) { success, _, error in
                    XCTAssertTrue(error == nil)
                    XCTAssertTrue(success == true)
                    expectation.fulfill()
                }
            }
        } else {
            XCTFail("Could not initialize collect post dispatcher")
        }

        waiter.wait(for: [expectation], timeout: 1.0)
    }

    func testDispatch() {
        let waiter = XCTWaiter(delegate: nil)
        let expectation = XCTestExpectation(description: "successful dispatch")
        _ = TealiumCollectPostDispatcher(dispatchURL: TealiumCollectPostDispatcher.defaultDispatchURL) { dispatcher in
            dispatcher?.dispatch(data: self.testDictionary) { success, _, error in
                XCTAssertTrue(error == nil)
                XCTAssertTrue(success == true)
                expectation.fulfill()
            }
        }
        waiter.wait(for: [expectation], timeout: 1.0)
    }

}
