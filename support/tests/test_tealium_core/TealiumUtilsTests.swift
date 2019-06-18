//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/6/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumUtilsTests: XCTestCase {

    let testJSONString = """
                            {\n  \"tealium_account\" : \"hello\",\n  \"tealium_environment\" : \"dev\",\n  \"tealium_profile\" : \"tester\"\n}
                            """

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testJSONStringWithDictionary() {
        let dictionary = ["tealium_account": "hello",
                          "tealium_environment": "dev",
                          "tealium_profile": "tester",
        ]

        XCTAssertTrue(testJSONString == jsonStringWithDictionary(dictionary))
    }

    func testURLRequest() {

        let urlRequest = urlPOSTRequestWithJSONString(testJSONString, dispatchURL: "https://collect.tealiumiq.com/event")

        XCTAssertTrue(urlRequest != nil)
        XCTAssertTrue(urlRequest?.httpMethod == "POST")
        XCTAssertTrue(urlRequest?.httpBody == testJSONString.data(using: .utf8))
    }

}
