//
//  SessionStarterTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class SessionStarterTests: XCTestCase {

    var sessionStarter: SessionStarterProtocol!
    var config: TealiumConfig!

    override func setUp() {
        config = TealiumConfig(account: "ssTestAccount", profile: "ssTestProfile", environment: "ssTestEnv")
        sessionStarter = SessionStarter(config: config, urlSession: MockURLSessionSessionStarter())
    }

    override func tearDown() { }

    func testSessionURL() {
        let sessionURL = sessionStarter.sessionURL
        XCTAssertEqual(true, sessionURL.hasPrefix("https://tags.tiqcdn.com/utag/tiqapp/utag.v.js?a=ssTestAccount/ssTestProfile/"))
    }

    func testRequestSessionSuccessful() {
        sessionStarter.requestSession { result in
            switch result {
            case .failure(let error):
                XCTFail("Did not receive successful response - error: \(error.localizedDescription)")
            case .success(let response):
                XCTAssertEqual(response.statusCode, 200)
            }
        }
    }

    func testRequestSessionErrorInResponse() {
        sessionStarter = SessionStarter(config: config, urlSession: MockURLSessionSessionStarterRequestError())
        sessionStarter.requestSession { result in
            switch result {
            case .failure(let error):
                if case SessionError.errorInRequest = error {
                    XCTAssertTrue(true)
                }
            case .success:
                XCTFail("Should not receive a successful response")
            }
        }
    }

    func testRequestSessionInvalidResponse() {
        sessionStarter = SessionStarter(config: config, urlSession: MockURLSessionSessionStarterInvalidResponse())
        sessionStarter.requestSession { result in
            switch result {
            case .failure(let error):
                if case SessionError.invalidResponse = error {
                    XCTAssertTrue(true)
                }
            case .success:
                XCTFail("Should not receive a successful response")
            }
        }
    }
}
