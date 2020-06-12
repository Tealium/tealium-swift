//
//  TealiumVisitorProfileRetrieverTests.swift
//  TealiumSwiftTests
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class TealiumVisitorProfileRetrieverTests: XCTestCase {

    var tealConfig: TealiumConfig!
    var visitorProfileRetriever: TealiumVisitorProfileRetriever!

    override func setUp() {
        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev", datasource: nil, optionalData: [:])
        visitorProfileRetriever = TealiumVisitorProfileRetriever(config: tealConfig, visitorId: "testVisitorId", urlSession: MockURLSession())
    }

    override func tearDown() {
    }

    func testVisitorProfileURL() {
        XCTAssertEqual("https://visitor-service.tealiumiq.com/\(tealConfig.account)/\(tealConfig.profile)/\(visitorProfileRetriever.tealiumVisitorId)",
            visitorProfileRetriever.visitorProfileURL)
    }

    func testIntervalSince() {
        let timeTraveler = TimeTraveler()

        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        var expectedResult: Int64 = 301_000

        var actualResult = visitorProfileRetriever.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        expectedResult = 241_000

        actualResult = visitorProfileRetriever.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

    }

    func testShouldFetch() {
        var result = visitorProfileRetriever.shouldFetch(basedOn: Date(), interval: 300_000, environment: "dev")
        XCTAssertEqual(true, result)

        result = visitorProfileRetriever.shouldFetch(basedOn: Date(), interval: nil, environment: "prod")
        XCTAssertEqual(true, result)

        let timeTraveler = TimeTraveler()
        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        result = visitorProfileRetriever.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertEqual(true, result)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        result = visitorProfileRetriever.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertEqual(false, result)
    }

    func testShouldFetchVisitorProfile() {
        let timeTraveler = TimeTraveler()

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev")
        visitorProfileRetriever.tealiumConfig = tealConfig
        visitorProfileRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(true, visitorProfileRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        tealConfig.visitorServiceRefreshInterval = 0
        visitorProfileRetriever = TealiumVisitorProfileRetriever(config: tealConfig, visitorId: "test")
        visitorProfileRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(true, visitorProfileRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        visitorProfileRetriever.tealiumConfig = tealConfig
        visitorProfileRetriever.lastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        XCTAssertEqual(true, visitorProfileRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        // resetting back to default
        tealConfig.visitorServiceRefreshInterval = 300
        visitorProfileRetriever = TealiumVisitorProfileRetriever(config: tealConfig, visitorId: "test")
        visitorProfileRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(false, visitorProfileRetriever.shouldFetchVisitorProfile)
    }

    func testSendURLRequest_Success() {
        let expect = expectation(description: "successful url request")
        let url = URL(string: "https://visitor-service.tealiumiq.com/tealiummobile/main/11CF7685E35542FEB93EB730A9A83BF2")!
        let request = URLRequest(url: url)
        visitorProfileRetriever.sendURLRequest(request) { _ in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testSendURLRequest_FailureInvalidURL() {
        let expect = expectation(description: "unsuccessful url request")
        let url = URL(string: "https://this.site.doesnotexist")!
        let request = URLRequest(url: url)
        visitorProfileRetriever.sendURLRequest(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error, NetworkError.unknownIssueWithSend)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testSendURLRequest_Non200Response() {
        let expect = expectation(description: "unsuccessful url request")
        let url = URL(string: "https://tealium.com/asdf/asdf.html")!
        let request = URLRequest(url: url)
        visitorProfileRetriever.sendURLRequest(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error, NetworkError.non200Response)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testSendURLRequest_CouldNotCreateSession() {
        let expect = expectation(description: "unsuccessful url request")
        let url = URL(string: "https://tealium.com/asdf/asdf.html")!
        let request = URLRequest(url: url)
        visitorProfileRetriever.urlSession = nil
        visitorProfileRetriever.sendURLRequest(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error, NetworkError.couldNotCreateSession)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    // Need MockURLSessionToWork
    func testDoNotFetchVisitorProfile() {
        let timeTraveler = TimeTraveler()
        let config = TealiumConfig(account: "test", profile: "test", environment: "prod", datasource: nil, optionalData: [:])
        let retriever = TealiumVisitorProfileRetriever(config: config, visitorId: "test")
        let expect = expectation(description: "should not fetch")
        retriever.lastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        retriever.fetchVisitorProfile { _ in
            XCTFail("Should not have fetched")
        }
        expect.fulfill()
        XCTAssertTrue(true)
        wait(for: [expect], timeout: 1.0)
    }

}
