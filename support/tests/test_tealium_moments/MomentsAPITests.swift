//
//  MomentsAPITests.swift
//  TealiumMoments
//
//  Created by Craig Rouse on 19/04/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumMoments
import XCTest

class MomentsAPITests: XCTestCase {
    func testFetchEngineResponseSuccess() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        let jsonData = """
    {
        "audiences": ["VIP", "Women's Apparel", "Lifetime visit count"],
        "badges": ["13", "26", "52"],
        "properties": {"5063": 6.1, "6021": "banner_007", "6022": "voucher_614", "6023": "https://domain.com/example.html"}
    }
    """.data(using: .utf8)!
        session.data = jsonData
        session.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        session.error = nil
        
        let expectation = XCTestExpectation(description: "Fetch engine response succeeds")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.audiences.count, 3)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected successful engine response, got failure")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseForbidden() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        let jsonData = "".data(using: .utf8)!
        session.data = jsonData
        session.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)
        session.error = nil
        
        let expectation = XCTestExpectation(description: "Fetch engine response fails")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success.")
            case .failure(let error):
                XCTAssertEqual((error as! MomentsAPIHTTPError), MomentsAPIHTTPError.forbidden, "Unexpected error type returned.")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseBadRequest() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        let jsonData = "".data(using: .utf8)!
        session.data = jsonData
        session.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
        session.error = nil
        
        let expectation = XCTestExpectation(description: "Fetch engine response fails")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success.")
            case .failure(let error):
                XCTAssertEqual((error as! MomentsAPIHTTPError), MomentsAPIHTTPError.badRequest, "Unexpected error type returned.")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseNotFound() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        let jsonData = "".data(using: .utf8)!
        session.data = jsonData
        session.response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        session.error = nil
        
        let expectation = XCTestExpectation(description: "Fetch engine response fails")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success.")
            case .failure(let error):
                XCTAssertEqual((error as! MomentsAPIHTTPError), MomentsAPIHTTPError.notFound, "Unexpected error type returned.")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseFailureMissingVisitorID() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        let expectation = XCTestExpectation(description: "Fetch engine response fails due to missing visitor ID")
        
        api.fetchEngineResponse(engineID: "engine123") { result in
            if case .failure(let error as MomentsError) = result, case .missingVisitorID = error {
                expectation.fulfill()
            } else {
                XCTFail("Expected failure with missing visitor ID, got other error")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseNetworkError() {
        let session = MockURLSession()
        let api = TealiumMomentsAPI(region: .us_east, account: "testAccount", profile: "testProfile", environment: "dev", session: session)
        session.error = NSError(domain: "network", code: -1009, userInfo: nil)
        
        let expectation = XCTestExpectation(description: "Fetch engine response fails due to network error")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            if case .failure(let error as NSError) = result, error.code == -1009 {
                expectation.fulfill()
            } else {
                XCTFail("Expected network error, got other error")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}
