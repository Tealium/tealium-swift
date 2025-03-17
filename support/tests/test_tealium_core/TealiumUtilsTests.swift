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

    func testJSONStringWithDictionary() throws {
        let dictionary: [String: Any] = ["tealium_account": "hello",
                                         "tealium_environment": "dev",
                                         "tealium_profile": "tester"
        ]

        let stringResult = try dictionary.toJSONString()
        XCTAssertTrue(testJSONString == stringResult)
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
            let jsonString = try? testDictionaries[(Int.random(in: 0..<4))].toJSONString()
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
            _ = NetworkUtils.urlPOSTRequestWithJSONString(jsonString!, dispatchURL: "https://collect.tealiumiq.com/event")
        }

    }
    
    func testIsValidURL() {
        
        let badURLs = [
            "Collect",
            "xfdufhdugh.sdfsdfn",
            "tealium",
            "212345.6462",
            "1",
            "12",
            "127",
            "127.",
            "127.0",
            "127.0.0",
            "127.0.0.",
            "127.0.0.1:",
            "127.0.0.1:123456",
            "file:127.0.0.1",
            "html://127.0.0.1",
            "http:127.0.0.1",
            "httpd://127.0.0.1",
            "file:127.0.0.1",
            "https:127.0.0.1",
            "htmls://127.0.0.1",
            "htts://127.0.0.1",
            "hello@hello.com",
            "http://hello@hello.com",
            "http://google.com@hello",
            "file:c:test",
            "ftp://test.com/",
            "git:test.com:path/to/res.git",
            "ssh:google.com",
            "http://localhost/",
            "https://localhost/",
            "localhost",
        ]
        
        let goodUrls = [
            "collect.tealiumiq.com",
            "collect.tealiumiq.com/event",
            "collect.tealiumiq.com/bulk-event",
            "https://collect.tealiumiq.com/bulk-event",
            "https://collect-eu-west-1.tealiumiq.com/event",
            "https://collect-eu-west-1.tealiumiq.com/bulk-event",
            "http://google.com/a/b/c/d/e/f/g",
            "http://google.com/a/b/c?",
            "http://google.com/a/b/c?z=2&y=hello",
            "http://google.com/a/b/c?text=%2FHi%2F",
            "https://google.com/a/b/c/d/e/f/g",
            "https://google.com/a/b/c?",
            "https://google.com/a/b/c?z=2&y=hello",
            "https://google.com/a/b/c?text=%2FHi%2F",
            "http://google.co",
            "http://google.com",
            "http://google.co.uk",
            "http://www.google.co",
            "http://www.google.com",
            "http://www.google.co.uk",
            "http://www.google.co.uk:12345",
            "https://google.co",
            "https://google.com",
            "https://google.co.uk",
            "https://www.google.co",
            "https://www.google.com",
            "https://www.google.co.uk",
            "https://www.google.co.uk:12345",
            "myMac.local",
            "https://127.0.0.1:1",
            "https://127.0.0.1:12",
            "https://127.0.0.1:123",
            "https://127.0.0.1:1234",
            "https://127.0.0.1:12345",
            "https://127.0.0.1:12345/",
            "https://127.0.0.1:12345/a",
            "https://127.0.0.1:12345/a/",
            "https://127.0.0.1:12345/a/b",
            "https://127.0.0.1:12345/a/b?",
            "https://127.0.0.1:12345/a/b?z",
            "https://127.0.0.1:12345/a/b?z=",
            "https://127.0.0.1:12345/a/b?z=%",
            "http://127.0.0.1:1",
            "http://127.0.0.1:12",
            "http://127.0.0.1:123",
            "http://127.0.0.1:1234",
            "http://127.0.0.1:12345",
            "http://127.0.0.1:12345/",
            "http://127.0.0.1:12345/a",
            "http://127.0.0.1:12345/a/",
            "http://127.0.0.1:12345/a/b",
            "http://127.0.0.1:12345/a/b?",
            "http://127.0.0.1:12345/a/b?z",
            "http://127.0.0.1:12345/a/b?z=",
            "http://127.0.0.1:12345/a/b?z=%",
            "127.0.0.1:1",
            "127.0.0.1:12",
            "127.0.0.1:123",
            "127.0.0.1:1234",
            "127.0.0.1:12345",
            "127.0.0.1:12345/",
            "127.0.0.1:12345/a",
            "127.0.0.1:12345/a/",
            "127.0.0.1:12345/a/b",
            "127.0.0.1:12345/a/b?",
            "127.0.0.1:12345/a/b?z",
            "127.0.0.1:12345/a/b?z=",
            "127.0.0.1:12345/a/b?z=%",
            "127.0.0.1",
            "127.0.0.1/",
            "127.0.0.1/a",
            "127.0.0.1/a/",
            "127.0.0.1/a/b",
            "127.0.0.1/a/b?",
            "127.0.0.1/a/b?z",
            "127.0.0.1/a/b?z=",
            "127.0.0.1/a/b?z=%"
        ]
        
        badURLs.forEach {
            XCTAssertFalse($0.isValidUrl, "Unexpected Success for url: \($0)")
        }
        
        goodUrls.forEach {
            XCTAssertTrue($0.isValidUrl, "Unexpected Failure for url: \($0)")
        }
    }

    private struct Container: Equatable {
        let dict: [String: Obj]
    }
    private struct Obj: Equatable {
        let str: String
    }
    func testEquatableDictionary() {
        let obj = Obj(str: "someValue")
        let dict = ["someKey" : obj]
        XCTAssertTrue(dict == dict) // Fails if custom `==` is implemented with NSDictionary.isEqual
        let container = Container(dict: dict)
        XCTAssertEqual(container, container) // Fails if custom `==` is implemented with NSDictionary.isEqual
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
