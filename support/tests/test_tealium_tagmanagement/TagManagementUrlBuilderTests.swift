//
//  TagManagementUrlBuilderTests.swift
//  TealiumTagManagementTests-iOS
//
//  Created by Enrico Zannini on 02/08/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumTagManagement
import TealiumCore

class TagManagementUrlBuilderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCompletionCalledWithoutModules() {
        let exp = expectation(description: "Completion called without modules")
        let baseURL = URL(string: "www.tealium.com")
        TagManagementUrlBuilder(modules: nil, baseURL: baseURL)
            .createUrl { _ in
                exp.fulfill()
            }
        waitForExpectations(timeout: 3)
    }

    func testQueryParamsAppended() {
        let exp = expectation(description: "Completion called with all query params")
        let baseURL = URL(string: "www.tealium.com")
        let query1 = [URLQueryItem(name: "firstKey", value: "firstValue"), URLQueryItem(name: "secondKey", value: "secondValue")]
        let query2 = [URLQueryItem(name: "thirdKey", value: "thirdValue"), URLQueryItem(name: "fourthKey", value: "fourthValue")]
        // A generous builder timeout keeps the params from being cut short under CI load; the
        // wait below is larger still so the test always gets a completion instead of hanging.
        TagManagementUrlBuilder(modules: [MockQueryParamsProvider(items: query1, delay: 1), MockQueryParamsProvider(items: query2, delay: 2)], baseURL: baseURL)
            .createUrl(timeout: 10) { url in
                guard let url = url,
                      let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
                    XCTFail("Expected a URL with query items")
                    exp.fulfill()
                    return
                }
                XCTAssertTrue(queryItems.elementsEqual(query1 + query2))
                exp.fulfill()
            }
        waitForExpectations(timeout: 12)
    }

    func testTimeout() {
        let exp = expectation(description: "Completion called with timeout")
        let baseURL = URL(string: "www.tealium.com")
        let query1 = [URLQueryItem(name: "firstKey", value: "firstValue"), URLQueryItem(name: "secondKey", value: "secondValue")]
        let query2 = [URLQueryItem(name: "thirdKey", value: "thirdValue"), URLQueryItem(name: "fourthKey", value: "fourthValue")]
        // The builder timeout is well below both provider delays so it always fires first and no
        // params make it into the URL. A wide margin avoids racing the deadline under CI load.
        TagManagementUrlBuilder(modules: [MockQueryParamsProvider(items: query1, delay: 2), MockQueryParamsProvider(items: query2, delay: 3)], baseURL: baseURL)
            .createUrl(timeout: 0.5) { url in
                guard let url = url else {
                    XCTFail("Expected the base URL on timeout")
                    exp.fulfill()
                    return
                }
                XCTAssertFalse(url.absoluteString.contains("firstKey"))
                exp.fulfill()
            }
        waitForExpectations(timeout: 5)
    }
}
