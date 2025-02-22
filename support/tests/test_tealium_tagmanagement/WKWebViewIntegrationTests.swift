//
//  WKWebViewIntegrationTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
#if os(iOS)
import WebKit
#endif
import XCTest

class WKWebViewIntegrationTests: XCTestCase {

    let config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    lazy var tagManagementWKWebView: TagManagementWKWebView = TagManagementWKWebView(config: config.copy, delegate: TagManagementModuleDelegate())
    lazy var testURL = config.webviewURL
    let userDefaults = UserDefaults(suiteName: #file)
    var module: TagManagementModule!
    var mockTagmanagement: MockTagManagementWebView!
    static var processPool = WKProcessPool()
    static var wkConfig: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.processPool = WKWebViewIntegrationTests.processPool
        config.allowsAirPlayForMediaPlayback = false
        return config
    }()

    override func setUp() {
        super.setUp()
        userDefaults?.removePersistentDomain(forName: #file)
    }

    func testWKWebViewInstance() {
        XCTAssertNotNil(tagManagementWKWebView, "Webview class unexpectedly nil")
        XCTAssertNil(tagManagementWKWebView.webview, "WKWebView instance should not be initialized until enable call")
        XCTAssertEqual(tagManagementWKWebView.isWebViewReady, false, "Webview was unexpectedly initialized")
    }

    func testEnableWebView() {
        let expectation = expectation(description: "testEnableWebView")
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            XCTAssertNotNil(self.tagManagementWKWebView.webview, "Webview instance was unexpectedly nil")
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }
    
    func testEnableWebViewWithProcessPool() {
        config.webviewProcessPool = WKWebViewIntegrationTests.processPool
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            DispatchQueue.main.async {
                let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
                let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
                XCTAssertEqual(originalAddress, moduleAddress)
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 10.0)
    }
    
    func testEnableWebViewWithoutProcessPool() {
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            DispatchQueue.main.async {
                let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
                let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
                XCTAssertNotEqual(originalAddress, moduleAddress)
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 10.0)
    }
    
    func testEnableWebViewWithConfig() {
        config.webviewConfig = WKWebViewIntegrationTests.wkConfig
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            DispatchQueue.main.async {
                let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
                let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
                
                XCTAssertEqual(originalAddress, moduleAddress)
                // check that custom property passed in config is present on Tealium webview. Default for this option is true if not specified.
                XCTAssertFalse(webview.webview!.configuration.allowsAirPlayForMediaPlayback)
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 10.0)
    }
    
    func testEnableWebViewWithoutConfig() {
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            DispatchQueue.main.async {
                let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
                let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
                XCTAssertNotEqual(originalAddress, moduleAddress)
                // check that custom property passed in config is present on Tealium webview
                XCTAssertTrue(webview.webview!.configuration.allowsAirPlayForMediaPlayback)
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 10.0)
    }

    func testDisableWebView() {
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, view: nil, completion: nil)
        tagManagementWKWebView.disable()
        XCTAssertNil(tagManagementWKWebView.webview, "WKWebView instance did not successfully deinit")
    }

    func testTrack() {
        let expectation = self.expectation(description: "testTrack")
        let data: [String: Any] = ["test_track": "track me"]
        let dataString = """
                        {\n  "test_track" : "track me"\n}
                        """
        let expectedJS = "utag.track(\'link\',\(dataString))"
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, view: nil, completion: nil)
        tagManagementWKWebView.track(data) { _, info, error in
            XCTAssertNil(error, "Error returned from track call")
            if let jsFromInfoDictionary = info[TealiumDataKey.jsCommand] as? String,
               let payload = info[TealiumDataKey.payload] as? [String: Any] {
                XCTAssertEqual(expectedJS, jsFromInfoDictionary, "Track call contained invalid data")
                XCTAssertEqual(data.description, payload.description, "Data and Payload should be equal")
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 5.0)
    }

    func testWebViewStateDidChange() {
        let expectation = self.expectation(description: "testWebViewStateDidChange")
        XCTAssertFalse(tagManagementWKWebView.isWebViewReady, "Webview should not be ready yet; webview has not been enabled")
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            XCTAssertTrue(self.tagManagementWKWebView.isWebViewReady, "Webview should be ready, but was found to be nil")
            self.tagManagementWKWebView.webviewStateDidChange(.loadFailure, withError: nil)
            XCTAssertFalse(self.tagManagementWKWebView.isWebViewReady, "Webview should not be ready - failure condition expected")
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5.0)
    }

    func testJavaScriptTrackCall() throws {
        let data: [String: Any] = ["test_track": "track me"]
        let dataString = """
                        {\n  "test_track" : "track me"\n}
                        """
        let expectedJS = "utag.track(\'link\',\(dataString))"
        if let actualJS = try data.tealiumJavaScriptTrackCall() {
            XCTAssertEqual(expectedJS, actualJS, "")
        }
    }

    func testDispatchTrackCreatesTrackRequest() {
        let expectation = expectation(description: "trackRequest")
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: TagManagementModuleDelegate(), completion: { [weak self] _ in
            let track = TealiumTrackRequest(data: ["test_track": true])
            self?.module?.dispatchTrack(track, completion: { result in
                switch result.0 {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error.localizedDescription)")
                case .success(let success):
                    XCTAssertTrue(success)
                    expectation.fulfill()
                }
            })
        })
        
        wait(for: [expectation], timeout: 5.0)
    }

    func testDispatchTrackCreatesBatchTrackRequest() {
        let expectation = expectation(description: "batchTrackRequest")
        let context = TestTealiumHelper.context(with: config)
        module = TagManagementModule(context: context, delegate: TagManagementModuleDelegate(), completion: { [weak self] _ in
            let track = TealiumTrackRequest(data: ["test_track": true])
            let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track])
            self?.module?.dispatchTrack(batchTrack, completion: { result in
                switch result.0 {
                case .failure(let error):
                    XCTFail("Unexpected error: \(error.localizedDescription)")
                case .success(let success):
                    XCTAssertTrue(success)
                    expectation.fulfill()
                }
            })
        })
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testModuleWithQueryParamProviderChangesUrl() {
        let expectation = expectation(description: "Enable complete")
        let config = self.config.copy
        config.collectors = [MockQueryParamsProvider.self]
        let tealium = Tealium(config: config)
        let context = tealium.context!
        module = TagManagementModule(context: context, delegate: TagManagementModuleDelegate(), completion: { _ in
            for item in MockQueryParamsProvider.defaultItems {
                XCTAssertTrue(URLComponents(url: self.module.tagManagement.url!, resolvingAgainstBaseURL: false)!.queryItems!.contains(item))
            }
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 5.0)
    }

}

class TagManagementModuleDelegate: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
