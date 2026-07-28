//
//  TealiumDelegateProxyTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class BaseProxyTests: XCTestCase {
    let mockDataLayer = DummyDataManagerAppDelegate()
    static var testNumber = 0

    var config: TealiumConfig {
        let config = TealiumConfig(account: "tealiummobile", profile: "\(TealiumDelegateProxyTests.testNumber))", environment: "dev")
        TealiumDelegateProxyTests.testNumber += 1
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        return config
    }

    @MainActor
    private func createTealium() async -> Tealium {
        await withCheckedContinuation { continuation in
            var tealium: Tealium?
            tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { _ in
                DispatchQueue.main.async {
                    if let tealium {
                        continuation.resume(returning: tealium)
                    } else {
                        fatalError("Tealium not initialized at completion time, should never happen.")
                    }
                }

            }
        }
    }

    var tealium: Tealium!

    override func setUp() async throws {
        self.tealium = await createTealium()
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        mockDataLayer.deleteAll()
        TealiumInstanceManager.shared.removeInstance(config: config)
        tealium = nil
    }

    func waitOnTealiumSerialQueue(block: @escaping () -> Void) async {
        await withCheckedContinuation { continuation in
            TealiumQueues.backgroundSerialQueue.async {
                block()
                continuation.resume(returning: ())
            }
        }
    }

    @MainActor
    func sendOpenUrlEvent(url: URL) {
        if #available(iOS 13.0, *), TealiumDelegateProxy.sceneEnabled {
            let scene = UIApplication.shared.connectedScenes.first!
            let sceneDelegate = scene.delegate!
            
            sceneDelegate.scene?(scene, openURLContexts: Set<UIOpenURLContext>.init([MockOpenUrlContext(url: url)]))
            
        } else {
            let appDelegate = UIApplication.shared.delegate!
            _ = appDelegate.application?(UIApplication.shared, open: url, options: [:])
        }
    }

    @MainActor
    func sendContinueUserActivityEvent(url: URL) {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        
        if #available(iOS 13.0, *), TealiumDelegateProxy.sceneEnabled {
            UIApplication.shared.manualSceneContinueUserActivity(activity)
        } else {
            UIApplication.shared.manualContinueUserActivity(activity)
        }
    }
}

class TealiumDelegateProxyTests: BaseProxyTests {

    func testOpenURL() async {
        let teal = tealium!
        let url = URL(string: "https://my-test-app.com/?test_param=true")!
        await sendOpenUrlEvent(url: url)
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true")
        }
    }

    func testOpenURLWithTraceId() async {
        let teal = tealium!
        let url = URL(string: "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")!
        await sendOpenUrlEvent(url: url)
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")
            XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "23456")
        }
    }

    func testUniversalLink() async {
        let teal = tealium!
        let url = URL(string: "https://www.tealium.com/universalLink/?universal_link=true")!
        await sendContinueUserActivityEvent(url: url)
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_universal_link"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true")
        }
    }

    func testUniversalLinkWithTraceId() async {
        let teal = tealium!
        let url = URL(string: "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")!
        await sendContinueUserActivityEvent(url: url)
        await waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "12345")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")
        }
    }
    
    func testRemovingContext() async {
        let context = tealium.context!
        XCTAssertTrue(TealiumDelegateProxy.contexts!.contains(context))
        tealium?.disable()
        tealium = nil
        await waitOnTealiumSerialQueue {
            XCTAssertFalse(TealiumDelegateProxy.contexts!.contains(context))
        }
    }
}

class DummyDataManagerAppDelegate: DataLayerManagerProtocol {
    var onDataUpdated: TealiumObservable<[String : Any]> = TealiumPublisher().asObservable()
    
    var onDataRemoved: TealiumCore.TealiumObservable<[String]> = TealiumPublisher().asObservable()
    
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

    func add(data: [String: Any], expiry: Expiry) {
        for (key,val) in data {
            add(key: key, value: val, expiry: expiry)
        }
    }

    func add(key: String, value: Any, expiry: Expiry) {
        switch expiry {
        case .session:
            all[key] = value
            return
        default:
            if key != "app_uuid" {
                XCTFail("Expiry should only be session")
            }
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

