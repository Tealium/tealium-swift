// 
// SceneDelegateProxyTests.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class SceneDelegateProxyTests: XCTestCase {

    let mockDataLayer = DummyDataManagerAppDelegate()
    var semaphore: DispatchSemaphore!
    static var testNumber = 0
    
    var shouldRunTest: Bool {
        ProcessInfo().operatingSystemVersion.majorVersion >= 13
    }

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
    
    
    func testOpenURLContexts() {
        guard shouldRunTest else {
            return
        }
        
        guard let scene = TealiumDelegateProxy.sharedApplication?.connectedScenes.first else {
            XCTFail("no scene")
            return
       }
        
        class MockURLContextInitable: UIOpenURLContext {
            override var url: URL {
                URL(string: "deeplink://tealium.com/?test_param=true&tealium_trace_id=23456")!
            }
            init(_: Void = ()) {}
        }
        
        class MockURLContext: MockURLContextInitable {
            init(){
                
            }
        }

        scene.delegate?.scene?(scene, openURLContexts: [MockURLContext()])
        XCTAssertEqual(self.tealium.dataLayer.all["deep_link_param_test_param"] as! String, "true")
        XCTAssertEqual(self.tealium.dataLayer.all["deep_link_url"] as! String, "deeplink://tealium.com/?test_param=true&tealium_trace_id=23456")
    }
    
    func testSceneContinueActivity() {
        guard shouldRunTest else {
            return
        }
        
        guard let scene = TealiumDelegateProxy.sharedApplication?.connectedScenes.first else {
            XCTFail("no scene")
            return
        }
        
        let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        userActivity.webpageURL = URL(string: "https://tealium.com/?test_param=continueUserActivity&tealium_trace_id=23456")!
        
        scene.delegate?.scene?(scene, continue: userActivity)
        
        XCTAssertEqual(self.tealium.dataLayer.all["deep_link_param_test_param"] as! String, "continueUserActivity")
        XCTAssertEqual(self.tealium.dataLayer.all["deep_link_url"] as! String, "https://tealium.com/?test_param=continueUserActivity&tealium_trace_id=23456")
    }

}
