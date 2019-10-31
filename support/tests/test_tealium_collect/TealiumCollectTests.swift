//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/6/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class TealiumCollectTests: XCTestCase {

    let testJSONString = """
                            {\n  \"tealium_account\" : \"hello\",\n  \"tealium_environment\" : \"dev\",\n  \"tealium_profile\" : \"tester\"\n}
                            """
    let testDictionary = ["tealium_account": "hello",
                          "tealium_environment": "dev",
                          "tealium_profile": "tester"
    ]

    var mockURLSession: URLSessionProtocol!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func validTestDataDictionary() -> [String: Any] {
        return [
            TealiumKey.account: "account",
            TealiumKey.profile: "profile" ,
            TealiumKey.environment: "environment" ,
            TealiumKey.event: "test" ,
            TealiumKey.libraryName: TealiumValue.libraryName ,
            TealiumKey.libraryVersion: TealiumValue.libraryVersion ,
            TealiumKey.sessionId: "someSessionId" ,
            TealiumKey.visitorId: "someVisitorId" ,
            "tealium_random": "someRandomNumber",
        ]
    }

    func testInitWithBaseURLString() {
        // invalid url
        let string = "tealium"
        _ = TealiumCollectPostDispatcher(dispatchURL: string) { success, error in
            guard !success else {
                XCTFail("unexpected success")
                return
            }
            guard error == .invalidDispatchURL else {
                XCTFail("Incorrect error returned")
                return
            }
        }
    }

    func testValidURL() {
        let validURL = "https://collect.tealiumiq.com/event/"
        XCTAssertTrue(TealiumCollectPostDispatcher.isValidUrl(url: validURL), "isValidURL returned unexpected failure")
        let invalidURL = "invalidURL"
        XCTAssertFalse(TealiumCollectPostDispatcher.isValidUrl(url: invalidURL), "isValidURL returned unexpected success")
    }

    func testSendURLRequest() {
        let waiter = XCTWaiter(delegate: nil)
        mockURLSession = MockURLSession()
        let expectation = XCTestExpectation(description: "successful dispatch")
        guard let request = urlPOSTRequestWithJSONString(testJSONString, dispatchURL: TealiumCollectPostDispatcher.defaultDispatchBaseURL) else {
            XCTFail("Could not initialize collect post dispatcher")
            return
        }

        let dispatcher = TealiumCollectPostDispatcher(dispatchURL: TealiumCollectPostDispatcher.defaultDispatchBaseURL, urlSession: mockURLSession)
        dispatcher.sendURLRequest(request) { success, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        waiter.wait(for: [expectation], timeout: 1.0)
    }

    func testDispatch() {
        let waiter = XCTWaiter(delegate: nil)
        mockURLSession = MockURLSession()
        let expectation = XCTestExpectation(description: "successful dispatch")
        let dispatcher = TealiumCollectPostDispatcher(dispatchURL: TealiumCollectPostDispatcher.defaultDispatchBaseURL, urlSession: mockURLSession)
        dispatcher.dispatch(data: self.testDictionary) { success, _, error in
            XCTAssertTrue(error == nil)
            XCTAssertTrue(success == true)
            expectation.fulfill()
        }
        waiter.wait(for: [expectation], timeout: 1.0)
    }

    func testDispatchWithError() {
        let waiter = XCTWaiter(delegate: nil)
        mockURLSession = MockURLSessionError()
        let expectation = XCTestExpectation(description: "failing dispatch")
        let dispatcher = TealiumCollectPostDispatcher(dispatchURL: TealiumCollectPostDispatcher.defaultDispatchBaseURL, urlSession: mockURLSession)
        dispatcher.dispatch(data: self.testDictionary) { success, _, error in
            guard let error = error as? TealiumCollectError else {
                XCTFail("Unexpected success")
                return
            }
            XCTAssertTrue(error == TealiumCollectError.xErrorDetected)
            XCTAssertTrue(success == false)
            expectation.fulfill()
        }
        waiter.wait(for: [expectation], timeout: 1.0)
    }

    func validCollectEndpoint(urlString: String) -> Bool {
        // TODO:

        return false
    }

}
