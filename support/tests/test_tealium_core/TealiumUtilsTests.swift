//
//  TealiumUtilsTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

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
        let dictionary: [String: Any] = ["tealium_account": "hello",
                                         "tealium_environment": "dev",
                                         "tealium_profile": "tester"
        ]

        XCTAssertTrue(testJSONString == dictionary.toJSONString)
    }

    func testURLRequest() {
        let urlRequest = NetworkUtils.urlPOSTRequestWithJSONString(self.testJSONString, dispatchURL: "https://collect.tealiumiq.com/event")
        XCTAssertNotNil(urlRequest, "URLRequest was nil")
        XCTAssertTrue(urlRequest?.httpMethod == "POST", "Unexpected request type")
        XCTAssertTrue(try! urlRequest?.httpBody?.gunzipped() == self.testJSONString.data(using: .utf8), "Unexpected request body")
    }

    func testURLRequestWithNaN() {
        let testDictionaries = [generateTestDict(), generateTestDict(), generateTestDict(), generateTestDict()]

        measure {
            let jsonString = testDictionaries[(Int.random(in: 0..<4))].toJSONString
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
        }

    }

}

func generateTestDict() -> [String: Any] {
    var dict = [String: Any]()

    for _ in 0..<200 {
        dict["\(Int.random(in: 1..<1_000_000_000))"] = "\(Int.random(in: 1..<1_000_000_000))"
    }

    dict["nan"] = Double.nan
    dict["infinity"] = Double.infinity
    dict["tealium_account"] = "hello"
    dict["tealium_environment"] = "dev"
    dict["tealium_profile"] = "tester"
    return dict
}
