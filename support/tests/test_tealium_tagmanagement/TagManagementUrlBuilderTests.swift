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
        let exp = expectation(description: "Completion called without modules")
        let baseURL = URL(string: "www.tealium.com")
        let query1 = [URLQueryItem(name: "firstKey", value: "firstValue"), URLQueryItem(name: "secondKey", value: "secondValue")]
        let query2 = [URLQueryItem(name: "thirdKey", value: "thirdValue"), URLQueryItem(name: "fourthKey", value: "fourthValue")]
        TagManagementUrlBuilder(modules: [MockQueryParamsProvider(items: query1, delay: 1), MockQueryParamsProvider(items: query2, delay: 2)], baseURL: baseURL)
            .createUrl { url in
                XCTAssertTrue(URLComponents(url: url!, resolvingAgainstBaseURL: false)!.queryItems!.elementsEqual(query1+query2))
                exp.fulfill()
            }
        waitForExpectations(timeout: 3)
    }

    func testTimeout() {
        let exp = expectation(description: "Completion called with timeout")
        let baseURL = URL(string: "www.tealium.com")
        let query1 = [URLQueryItem(name: "firstKey", value: "firstValue"), URLQueryItem(name: "secondKey", value: "secondValue")]
        let query2 = [URLQueryItem(name: "thirdKey", value: "thirdValue"), URLQueryItem(name: "fourthKey", value: "fourthValue")]
        TagManagementUrlBuilder(modules: [MockQueryParamsProvider(items: query1, delay: 1), MockQueryParamsProvider(items: query2, delay: 4)], baseURL: baseURL)
            .createUrl(timeout: 1.0) { url in
                XCTAssertFalse(url!.absoluteString.contains("firstKey"))
                exp.fulfill()
            }
        waitForExpectations(timeout: 3)
    }
}
