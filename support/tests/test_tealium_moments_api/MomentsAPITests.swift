//
//  MomentsAPITests.swift
//  tealium-swift
//
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumMomentsAPI
import XCTest

class MomentsAPITests: XCTestCase {
    
    static let customReferer = "https://tealium.com/"
    static let account = "testAccount"
    static let profile = "testProfile"
    static let environment = "dev"
    static let standardReferer = "https://tags.tiqcdn.com/utag/\(account)/\(profile)/\(environment)/mobile.html"
    let mockURLSession = MockURLSession()
    
    func testFetchEngineResponseSuccess() {
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
        let jsonData = """
        {"audiences":["VIP", "Women's Apparel", "Lifetime visit count"],
         "badges":["13", "26", "52"],
         "properties":{"54":"other","58":"other","60":"mobile application","5123":"set","5240":"Visitor: String Attribute","5688":"1970-01-01"},
         "metrics":{"15":5,"21":5,"22":43,"25":2.7933666666666666},
         "flags":{"27":true,"5152":true,"5242":false},
         "dates":{"23":1718202502203,"24":1718357687966,"5244":1718360309656,"5690":0}}
        """.data(using: .utf8)!
        
        mockURLSession.result = .success(withData: jsonData, statusCode: 200)
        
        let expectation = XCTestExpectation(description: "Fetch engine response succeeds")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.audiences.count, 3)
                XCTAssertEqual(response.dates.count, 4)
                XCTAssertEqual(response.badges.count, 3)
                XCTAssertEqual(response.strings.count, 6)
                XCTAssertEqual(response.booleans.count, 3)
                XCTAssertEqual(response.numbers.count, 4)
                XCTAssertEqual(response.numbers["25"]!, 2.7933666666666666)
                XCTAssertEqual(response.booleans["5242"]!, false)
                
                expectation.fulfill()
            case .failure:
                XCTFail("Expected successful engine response, got failure")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFetchEngineResponseForbidden() {
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
        mockURLSession.result = .success(withData: nil, statusCode: 403)
        
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
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
        mockURLSession.result = .success(withData: nil, statusCode: 400)
        
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
    
    func testFetchEngineResponseCustomReferer() {
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, referer: MomentsAPITests.customReferer, session: mockURLSession)
        
        mockURLSession.result = .success(withData: nil, statusCode: 200)
        
        let requestSent = expectation(description: "Request sent")
        mockURLSession.onRequestSent.subscribeOnce { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Referer"), MomentsAPITests.customReferer)
            requestSent.fulfill()
        }
        
        let expectation = XCTestExpectation(description: "Custom referer is correctly set")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            expectation.fulfill()
        }
        
        wait(for: [expectation, requestSent], timeout: 1.0)
    }
    
    func testFetchEngineResponseNotFound() {
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
        mockURLSession.result = .success(withData: nil, statusCode: 404)
        
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
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
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
        let api = TealiumMomentsAPI(region: .us_east, account: MomentsAPITests.account, profile: MomentsAPITests.profile, environment: MomentsAPITests.environment, session: mockURLSession)
        
        mockURLSession.result = .failure(URLError(URLError.Code.notConnectedToInternet))
        
        let expectation = XCTestExpectation(description: "Fetch engine response fails due to network error")
        
        api.visitorId = "12345"
        api.fetchEngineResponse(engineID: "engine123") { result in
            if case .failure(let error as URLError) = result, error.code == .notConnectedToInternet {
                expectation.fulfill()
            } else {
                XCTFail("Expected network error, got other error")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

