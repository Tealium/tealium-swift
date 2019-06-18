//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/6/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumCollectTests: XCTestCase {

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
            TealiumVolatileDataKey.sessionId: "someSessionId" ,
            TealiumAppDataKey.visitorId: "someVisitorId" ,
            TealiumVolatileDataKey.random: "someRandomNumber",
        ]
    }

    func isValidCollectDictionary(dictionary: [String: Any]) -> Bool {
        for (key, value) in dictionary {
            if value is String ||
                value is [String] {

                // Do nothing - is there not a better way to do this?

            } else {
                print("Key: \(key) contains neither a String or [String] value.")
                return false

            }

        }

        return true
    }

    func testEncodeDictionaryToString() {
        let expectedString = "buzz=chi&gamma=fizz&key=%5B%22foo%22,%20%22bar%22,%20%22alpha%22,%20%22segment%22,%20%22sigma%22%5D&lambda=closure"

        let dictionary = ["key": ["foo", "bar", "alpha", "segment", "sigma"],
                          "gamma": "fizz",
                          "buzz": "chi",
                          "lambda": "closure"] as [String: Any]
        let collect = TealiumCollect(baseURL: TealiumCollect.defaultBaseURLString())
        let testString = collect.encode(dictionary: dictionary as [String: AnyObject])

        XCTAssertTrue(expectedString == testString, "test string \(testString) is not encoded properly: expected \(expectedString).")
    }

    func testInitWithBaseURLString() {
        let string = "http://www.blingbling.com"
        let collect = TealiumCollect(baseURL: string)
        let baseURLString = collect.getBaseURLString()

        XCTAssertTrue(string == baseURLString, "baseURLString did not set property: \(baseURLString) detected.")
    }

    func testSanitization() {
        let set: Set<String> = ["value1", "value2"]

        let data = [
            "string": "value",
            "stringArray": ["v1", "v2"],
            "dictionary": ["key": "value"],
            "set": set,
            "number": 15,
        ] as [String: Any]

        XCTAssertFalse(isValidCollectDictionary(dictionary: data))

        let sanitized = TealiumCollect.sanitized(dictionary: data)

        XCTAssertTrue(data.count == sanitized.count, "Content mismatch between pre and post sanitized dictionary: pre: \(data) - post:\(sanitized)")
        XCTAssertTrue(isValidCollectDictionary(dictionary: sanitized))
    }

    // TODO: Replace with mock object testing
    func testDispatch() {
        // Check to see that encoding with dispatch was correctly converted to expected URL
        // NOTE: We'll always need to update this expected URL with the current lib version. This is fine, sort of an extra layer of check on that value prior to production release.
        let expectedURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_account=account&tealium_environment=environment&tealium_event=test&tealium_library_name=swift&tealium_library_version=\(TealiumValue.libraryVersion)&tealium_profile=profile&tealium_random=someRandomNumber&tealium_session_id=someSessionId&tealium_visitor_id=someVisitorId"

        let collect = TealiumCollect(baseURL: TealiumCollect.defaultBaseURLString())
        let expectation = self.expectation(description: "dispatch")

        collect.dispatch(data: validTestDataDictionary()) { _, info, _ in

            guard let encodedURLString = info?[TealiumCollectKey.encodedURLString] as? String else {
                XCTFail("Could not retrieve encoded url from info dictionary: \(String(describing: info))")
                return
            }

            XCTAssertTrue(expectedURL == encodedURLString, "\n\nUnexpected encoded url string used by dispatch: \(encodedURLString) \n\nexpectedURL: \(expectedURL)")
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 6.0, handler: nil)
    }

    // TODO: Replace with mock object testing
    func testInvalidSend() {
        // Fire off to a non-existent URL
        let invalidURL = "https://this.site.doesnotexist"
        let collect = TealiumCollect(baseURL: "thisURLdoesntMatter")
        let expectation = self.expectation(description: "invalidSend")

        collect.send(finalStringWithParams: invalidURL) { success, _, _ in
            XCTAssertFalse(success, "Send did not result in expected fail for address: \(invalidURL)")
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    // TODO: Replace with mock object testing - This will fail if the test is run without wifi and responding server.
    func testValidSend() {
        let validURL = "https://collect.tealiumiq.com/vdata/i.gif?tealium_library_version=1.1.2&tealium_session_id=someSessionId&tealium_library_name=swift&tealium_random=someRandomNumber&tealium_account=account&tealium_profile=profile&tealium_environment=environment&tealium_visitor_id=someVisitorId&tealium_firstparty_visitor_id=someVisitorId"

        let collect = TealiumCollect(baseURL: "thisURLdoesntMatter")
        let expectation = self.expectation(description: "validSend")

        collect.send(finalStringWithParams: validURL,
                     completion: { success, _, _ in

                XCTAssertTrue(success, "Send failed to this address: \(validURL)")
                expectation.fulfill()

        })

        self.waitForExpectations(timeout: 4.0, handler: nil)
    }

    func validCollectEndpoint(urlString: String) -> Bool {
        // TODO:

        return false
    }

}
