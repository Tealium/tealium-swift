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
    let visitorId = "testVisitorId"

    override func setUp() {
        tealConfig = TealiumConfig(account: "test", profile: "test", environment: "dev", dataSource: nil, options: [:])
        visitorServiceRetriever = VisitorServiceRetriever(config: tealConfig, urlSession: MockURLSession())
    }

    override func tearDown() {
    }

    func testVisitorServiceURL() {
        XCTAssertEqual("https://visitor-service.tealiumiq.com/\(tealConfig.account)/\(tealConfig.profile)/\(visitorId)",
                       visitorServiceRetriever.visitorServiceURL(tealiumVisitorId: visitorId))
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

}
