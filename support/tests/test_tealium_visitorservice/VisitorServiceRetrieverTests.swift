//
//  VisitorServiceRetrieverTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class VisitorServiceRetrieverTests: XCTestCase {

    var tealConfig: TealiumConfig!
    var visitorServiceRetriever: VisitorServiceRetriever!

    override func setUp() {
        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev", dataSource: nil, options: [:])
        visitorServiceRetriever = VisitorServiceRetriever(config: tealConfig, visitorId: "testVisitorId", urlSession: MockURLSession())
    }

    override func tearDown() {
    }

    func testVisitorServiceURL() {
        XCTAssertEqual("https://visitor-service.tealiumiq.com/\(tealConfig.account)/\(tealConfig.profile)/\(visitorServiceRetriever.tealiumVisitorId)",
                       visitorServiceRetriever.visitorServiceURL)
    }

    func testIntervalSince() {
        let timeTraveler = TimeTraveler()

        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        var expectedResult: Int64 = 301_000

        var actualResult = visitorServiceRetriever.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        expectedResult = 241_000

        actualResult = visitorServiceRetriever.intervalSince(lastFetch: mockedLastFetch)

        XCTAssertEqual(expectedResult, actualResult)

    }

    func testShouldFetch() {
        var result = visitorServiceRetriever.shouldFetch(basedOn: Date(), interval: 300_000, environment: "dev")
        XCTAssertEqual(true, result)

        result = visitorServiceRetriever.shouldFetch(basedOn: Date(), interval: nil, environment: "prod")
        XCTAssertEqual(true, result)

        let timeTraveler = TimeTraveler()
        var mockedLastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        result = visitorServiceRetriever.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertEqual(true, result)

        mockedLastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        result = visitorServiceRetriever.shouldFetch(basedOn: mockedLastFetch, interval: 300_000, environment: "prod")
        XCTAssertEqual(false, result)
    }

    func testShouldFetchVisitorProfile() {
        let timeTraveler = TimeTraveler()

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev")
        visitorServiceRetriever.tealiumConfig = tealConfig
        visitorServiceRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(true, visitorServiceRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        tealConfig.visitorServiceRefresh = .every(0, .seconds)
        visitorServiceRetriever = VisitorServiceRetriever(config: tealConfig, visitorId: "test")
        visitorServiceRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(true, visitorServiceRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        visitorServiceRetriever.tealiumConfig = tealConfig
        visitorServiceRetriever.lastFetch = timeTraveler.travel(by: (60 * 5 + 1) * -1)
        XCTAssertEqual(true, visitorServiceRetriever.shouldFetchVisitorProfile)

        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "prod")
        // resetting back to default
        tealConfig.visitorServiceRefresh = .every(5, .minutes)
        visitorServiceRetriever = VisitorServiceRetriever(config: tealConfig, visitorId: "test")
        visitorServiceRetriever.lastFetch = timeTraveler.travel(by: (60 * 2 + 1) * -1)
        XCTAssertEqual(false, visitorServiceRetriever.shouldFetchVisitorProfile)
    }

    func testSendURLRequest_Success() {
        let expect = expectation(description: "successful url request")
        let url = URL(string: "https://visitor-service.tealiumiq.com/tealiummobile/main/11CF7685E35542FEB93EB730A9A83BF2")!
        let request = URLRequest(url: url)
        visitorServiceRetriever.sendURLRequest(request) { _ in
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testSendURLRequest_FailureInvalidURL() {
        let expect = expectation(description: "unsuccessful url request")
        let url = URL(string: "https://this.site.doesnotexist")!
        let request = URLRequest(url: url)
        visitorServiceRetriever.sendURLRequest(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error, NetworkError.unknownIssueWithSend)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testSendURLRequest_Non200Response() {
        let expect = expectation(description: "unsuccessful url request")
        let url = URL(string: "https://tealium.com/asdf/asdf.html")!
        let request = URLRequest(url: url)
        visitorServiceRetriever.sendURLRequest(request) { result in
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
        visitorServiceRetriever.urlSession = nil
        visitorServiceRetriever.sendURLRequest(request) { result in
            if case .failure(let error) = result {
                XCTAssertEqual(error, NetworkError.couldNotCreateSession)
            }
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3.0)
    }

    func testDoNotFetchVisitorProfile() {
        let timeTraveler = TimeTraveler()
        let config = TealiumConfig(account: "test", profile: "test", environment: "prod", dataSource: nil, options: [:])
        let retriever = VisitorServiceRetriever(config: config, visitorId: "test", urlSession: MockURLSession())
        let expect = expectation(description: "should not fetch")
        retriever.lastFetch = timeTraveler.travel(by: (60 * 4 + 1) * -1)
        retriever.fetchVisitorProfile { result in
            if case .success(let profile) = result {
                XCTAssertNil(profile)
                expect.fulfill()
            }
        }
        wait(for: [expect], timeout: 1.0)
    }

}
