//
//  TealiumTraceTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class TealiumTraceTests: XCTestCase {
    
    var defaultTealiumConfig: TealiumConfig { TealiumConfig(account: "tealiummobile",
                                                            profile: "demo",
                                                            environment: "dev",
                                                            options: nil)
    }

    var mockDataLayer = DummyDataManagerTrace()
    static var expectation: XCTestExpectation!
    var semaphore: DispatchSemaphore!
    var testTraceId: String {
        "\(Int.random(in: 100_000...999_999))"
    }
    func tealiumForConfig(config: TealiumConfig, _ completion: (Tealium) -> Void) {
        let localSempahore = DispatchSemaphore(value: 0)
        config.logLevel = .silent
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
            localSempahore.signal()
        }
        localSempahore.wait()
        completion(tealium)
    }

    var testTealium: Tealium {
        let config = defaultTealiumConfig
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.dispatchListeners = [self]
        config.batchingEnabled = false
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
            self.semaphore.signal()
        }
        return tealium
    }

    var tealium: Tealium!
    override func setUpWithError() throws {
        semaphore = DispatchSemaphore(value: 0)
        tealium = testTealium
        semaphore.wait()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        tealium = nil
    }

    func testJoinTrace() {
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        XCTAssertEqual(mockDataLayer.traceId, testTraceId)
    }

    func testLeaveTrace() {
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        XCTAssertEqual(mockDataLayer.traceId, testTraceId)
        tealium.leaveTrace()
        XCTAssertNil(mockDataLayer.traceId)
    }

    func testKillVisitorSession() {
        TealiumTraceTests.expectation = self.expectation(description: "testKillVisitorSession")
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        tealium.killTraceVisitorSession()
        wait(for: [TealiumTraceTests.expectation], timeout: 3.0)
    }

    func testHandleDeepLink_joinTrace() {
        let testTraceId = self.testTraceId
        let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)")!
        tealium.handleDeepLink(link)
        XCTAssertEqual(mockDataLayer.traceId!, testTraceId)
    }

    func testHandleDeepLink_joinTraceDoesNotRunIfQRTraceDisabled() {
        TealiumTraceTests.expectation = self.expectation(description: "testHandleDeepLink_joinTraceDoesNotRunIfQRTraceDisabled")
        let config = defaultTealiumConfig
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        config.qrTraceEnabled = false
        tealiumForConfig(config: config) { tealium in
            let testTraceId = self.testTraceId
            let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)")!
            tealium.handleDeepLink(link)
            XCTAssertNil(mockDataLayer.traceId)
            TealiumTraceTests.expectation.fulfill()
        }

        wait(for: [TealiumTraceTests.expectation], timeout: 3.0)
    }

    func testHandleDeepLink_leaveTrace() {
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        XCTAssertEqual(mockDataLayer.traceId, testTraceId)
        let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)&leave_trace")!
        tealium.handleDeepLink(link)
        XCTAssertNil(mockDataLayer.traceId)
    }

    func testHandleDeepLink_leaveTraceWithKillVisitorSession() {
        TealiumTraceTests.expectation = self.expectation(description: "testHandleDeepLink_leaveTraceWithKillVisitorSession")
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)&kill_visitor_session&leave_trace")!
        tealium.handleDeepLink(link)
        waitForExpectations(timeout: 3.0) { _ in
            XCTAssertNil(self.mockDataLayer.traceId)
        }
    }

    func testHandleDeepLink_killVisitorSessionOnly() {
        TealiumTraceTests.expectation = self.expectation(description: "testHandleDeepLink_killVisitorSessionOnly")
        let testTraceId = self.testTraceId
        tealium.joinTrace(id: testTraceId)
        let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)&kill_visitor_session")!
        tealium.handleDeepLink(link)
        wait(for: [TealiumTraceTests.expectation], timeout: 3.0)
    }

    func testHandleDeepLink() {
        let link = URL(string: "https://tealium.com?tealium_trace_id=abc123&utm_param_1=hello&utm_param_2=test")!
        tealium.handleDeepLink(link)
        XCTAssertEqual(mockDataLayer.all[TealiumKey.deepLinkURL] as! String, link.absoluteString)
        XCTAssertEqual(mockDataLayer.all["deep_link_param_utm_param_1"] as! String, "hello")
        XCTAssertEqual(mockDataLayer.all["deep_link_param_utm_param_2"] as! String, "test")
    }

    func testHandleDeepLinkDoesNotAddDataIfDisabled() {
        TealiumTraceTests.expectation = self.expectation(description: "testHandleDeepLinkDoesNotAddDataIfDisabled")
        let config = defaultTealiumConfig
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        config.deepLinkTrackingEnabled = false
        tealiumForConfig(config: config) { tealium in
            let link = URL(string: "https://tealium.com?tealium_trace_id=\(testTraceId)&utm_param_1=hello&utm_param_2=test")!
            tealium.handleDeepLink(link)
            XCTAssertNil(mockDataLayer.all[TealiumKey.deepLinkURL])
            XCTAssertNil(mockDataLayer.all["deep_link_param_utm_param_1"])
            XCTAssertNil(mockDataLayer.all["deep_link_param_utm_param_2"])
            TealiumTraceTests.expectation.fulfill()
        }

        wait(for: [TealiumTraceTests.expectation], timeout: 3.0)
    }
}

extension TealiumTraceTests: DispatchListener {
    func willTrack(request: TealiumRequest) {
        let request = request as! TealiumTrackRequest
        XCTAssertTrue(request.event == "kill_visitor_session")
        XCTAssertEqual(request.trackDictionary["event"] as! String, "kill_visitor_session")
        TealiumTraceTests.expectation.fulfill()
    }
}

class DummyDataManagerTrace: DataLayerManagerProtocol {

    var traceId: String? {
        willSet {
            all["cp.trace_id"] = newValue
        }
    }
    var all: [String: Any] = [:] {
        willSet {
            print("Willset to:\(self.all.debugDescription)")
        }
    }

    var allSessionData: [String: Any] = ["sessionData": true]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = ["sessionData": true]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: testTealiumConfig)

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry?) {

    }

    func add(key: String, value: Any, expiry: Expiry?) {
        all[key] = value
        switch expiry {
        case .session:
            return
        default:
            XCTFail()
        }
    }

    func joinTrace(id: String) {
        traceId = id
    }

    func delete(for Keys: [String]) {

    }

    func delete(for key: String) {

    }

    func deleteAll() {

    }

    func leaveTrace() {
        traceId = nil
    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}
