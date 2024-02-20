//
//  TealiumDelegateProxyTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class TealiumDelegateProxyTests: XCTestCase {

    let mockDataLayer = DummyDataManagerAppDelegate()
    var semaphore: DispatchSemaphore!
    static var testNumber = 0

    var config: TealiumConfig {
        let config = TealiumConfig(account: "tealiummobile", profile: "\(TealiumDelegateProxyTests.testNumber))", environment: "dev")
        TealiumDelegateProxyTests.testNumber += 1
        config.logLevel = .silent
        config.dispatchers = [Dispatchers.Collect]
        config.batchingEnabled = false
        return config
    }
    var testTealium: Tealium {
        let tealium = Tealium(config: config, dataLayer: mockDataLayer, modulesManager: nil) { [weak self] _ in
            self?.semaphore.signal()
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
        TealiumInstanceManager.shared.removeInstance(config: config)
        tealium = nil
    }
    
    func testOpenURL() {
        let teal = tealium!
        let url = URL(string: "https://my-test-app.com/?test_param=true")!
        sendOpenUrlEvent(url: url)
        waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true")
        }
    }

    func testOpenURLWithTraceId() {
        let teal = tealium!
        let url = URL(string: "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")!
        sendOpenUrlEvent(url: url)
        waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_test_param"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://my-test-app.com/?test_param=true&tealium_trace_id=23456")
            XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "23456")
        }
    }

    func testUniversalLink() {
        let teal = tealium!
        let url = URL(string: "https://www.tealium.com/universalLink/?universal_link=true")!
        sendContinueUserActivityEvent(url: url)
        waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["deep_link_param_universal_link"] as! String, "true")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true")
        }
    }

    func testUniversalLinkWithTraceId() {
        let teal = tealium!
        let url = URL(string: "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")!
        sendContinueUserActivityEvent(url: url)
        waitOnTealiumSerialQueue {
            XCTAssertEqual(teal.dataLayer.all["cp.trace_id"] as! String, "12345")
            XCTAssertEqual(teal.dataLayer.all["deep_link_url"] as! String, "https://www.tealium.com/universalLink/?universal_link=true&tealium_trace_id=12345")
        }
    }
    
    func testRemovingContext() {
        let context = tealium.context!
        XCTAssertTrue(TealiumDelegateProxy.contexts!.contains(context))
        tealium?.disable()
        tealium = nil
        waitOnTealiumSerialQueue {
            XCTAssertFalse(TealiumDelegateProxy.contexts!.contains(context))
        }
    }
    
    func waitOnTealiumSerialQueue(_ block: @escaping () -> ()) {
        TealiumQueues.backgroundSerialQueue.sync {
            block()
        }
    }
    
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

