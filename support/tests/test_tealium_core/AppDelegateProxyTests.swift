//
//  AppDelegateProxyTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class AppDelegateProxyTests: XCTestCase {

    let mockDataLayer = DummyDataManagerAppDelegate()
    var semaphore: DispatchSemaphore!
    static var testNumber = 0

    var testTealium: Tealium {
        let config = TealiumConfig(account: "tealiummobile", profile: "\(AppDelegateProxyTests.testNumber))", environment: "dev")
        AppDelegateProxyTests.testNumber += 1
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
            self.semaphore.signal()
        }
        return tealium
    }

    var testTealiumWithoutProxy: Tealium {
        let config = TealiumConfig(account: "tealiummobile", profile: "\(AppDelegateProxyTests.testNumber))", environment: "dev")
        AppDelegateProxyTests.testNumber += 1
        config.appDelegateProxyEnabled = false
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
            self.semaphore.signal()
        }
        return tealium
    }

    var tealium: Tealium!

    override func setUpWithError() throws {
        self.semaphore = DispatchSemaphore(value: 0)
        self.tealium = testTealium
        self.semaphore.wait()
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        mockDataLayer.deleteAll()
        tealium = nil
    }

    func testOpenURL() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        _ = appDelegate.application?(UIApplication.shared, open: URL(string: "https://my-test-app.com/?test_param=true")!, options: [:])
        XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
        XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true")
    }

    func testOpenURLWithTraceId() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        _ = appDelegate.application?(UIApplication.shared, open: URL(string: "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")!, options: [:])
        XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
        XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")
        XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "23456")
    }

    func testUniversalLink() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://www.tealium.com/universalLink/?universal_link=true")!
        appDelegate.application?(UIApplication.shared, didUpdate: activity)
        XCTAssertEqual(teal.dataLayer.all["deep_link_param_universal_link"] as! String, "true")
        XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true")
    }

    func testUniversalLinkWithTraceId() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")!
        appDelegate.application?(UIApplication.shared, didUpdate: activity)
        XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "12345")
        XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")
    }
}

// Needs to be separate test class, since there's no easy way to undo the proxy in between tests
class AppDelegateProxyTestsWithoutProxy: XCTestCase {

    let mockDataLayer = DummyDataManagerAppDelegate()
    var semaphore: DispatchSemaphore!
    static var testNumber = 0

    var testTealiumWithoutProxy: Tealium {
        let config = TealiumConfig(account: "tealiummobile", profile: "\(AppDelegateProxyTestsWithoutProxy.testNumber))", environment: "dev")
        AppDelegateProxyTestsWithoutProxy.testNumber += 1
        config.appDelegateProxyEnabled = false
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
            self.semaphore.signal()
        }
        return tealium
    }

    var tealium: Tealium!

    override func setUpWithError() throws {
        self.semaphore = DispatchSemaphore(value: 0)
        self.tealium = testTealiumWithoutProxy
        self.semaphore.wait()
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        mockDataLayer.deleteAll()
        tealium = nil
    }

    func testUniversalLinkNotCalledIfAppDelegateProxyDisabled() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")!
        appDelegate.application?(UIApplication.shared, didUpdate: activity)
        XCTAssertNil(teal.dataLayer.all["cp.trace_id"])
        XCTAssertNil(teal.dataLayer.all["deep_link_url"])
    }

    func testOpenURLWithTraceIdNotCalledIfAppDelegateProxyDisabled() throws {
        let teal = tealium!
        let appDelegate = UIApplication.shared.delegate!
        _ = appDelegate.application?(UIApplication.shared, open: URL(string: "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")!, options: [:])
        XCTAssertNil(teal.dataLayer.all["cp.trace_id"])
        XCTAssertNil(teal.dataLayer.all["deep_link_url"])
    }
}

class DummyDataManagerAppDelegate: DataLayerManagerProtocol {
    var traceId: String? {
        willSet {
            all["cp.trace_id"] = newValue
        }
    }

    var all: [String: Any] = [:]

    var allSessionData: [String: Any] = [:]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = [:]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: testTealiumConfig)

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry?) {

    }

    func add(key: String, value: Any, expiry: Expiry?) {
        switch expiry {
        case .session:
            all[key] = value
            return
        default:
            XCTFail("Expiry should only be session")
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
        all.removeAll()
    }

    func leaveTrace() {

    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}
