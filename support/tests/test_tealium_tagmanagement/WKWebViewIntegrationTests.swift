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

@available(iOS 11.0, *)
class WKWebViewIntegrationTests: XCTestCase {

    let tagManagementWKWebView: TagManagementWKWebView = TagManagementWKWebView(config: testTealiumConfig.copy, delegate: TagManagementModuleDelegate())
    let testURL = TestTealiumHelper().newConfig().webviewURL
    let userDefaults = UserDefaults(suiteName: #file)

    var expect: XCTestExpectation!
    var module: TagManagementModule!
    var config: TealiumConfig!
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
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnv")
    }

    func testWKWebViewInstance() {
        XCTAssertNotNil(tagManagementWKWebView, "Webview class unexpectedly nil")
        XCTAssertNil(tagManagementWKWebView.webview, "WKWebView instance should not be initialized until enable call")
        XCTAssertEqual(tagManagementWKWebView.isWebViewReady, false, "Webview was unexpectedly initialized")
    }

    func testEnableWebView() {
        let expectation = self.expectation(description: "testEnableWebView")
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            XCTAssertNotNil(self.tagManagementWKWebView.webview, "Webview instance was unexpectedly nil")
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }
    
    func testEnableWebViewWithProcessPool() {
        let config = self.config.copy
        config.webviewProcessPool = WKWebViewIntegrationTests.processPool
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
            let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
            XCTAssertEqual(originalAddress, moduleAddress)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }
    
    func testEnableWebViewWithoutProcessPool() {
        let config = self.config.copy
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
            let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
            XCTAssertNotEqual(originalAddress, moduleAddress)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }
    
    func testEnableWebViewWithConfig() {
        let config = self.config.copy
        config.webviewConfig = WKWebViewIntegrationTests.wkConfig
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
            let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
            XCTAssertEqual(originalAddress, moduleAddress)
            // check that custom property passed in config is present on Tealium webview. Default for this option is true if not specified.
            XCTAssertFalse(webview.webview!.configuration.allowsAirPlayForMediaPlayback)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }
    
    func testEnableWebViewWithoutConfig() {
        let config = self.config.copy
        let webview = TagManagementWKWebView(config: config, delegate: TagManagementModuleDelegate())
        let expectation = self.expectation(description: "testEnableWebView")
        webview.enable(webviewURL: testURL, delegates: nil, view: nil) { _, _ in
            let originalAddress = Unmanaged.passUnretained(WKWebViewIntegrationTests.processPool).toOpaque()
            let moduleAddress = Unmanaged.passUnretained(webview.webview!.configuration.processPool).toOpaque()
            XCTAssertNotEqual(originalAddress, moduleAddress)
            // check that custom property passed in config is present on Tealium webview
            XCTAssertTrue(webview.webview!.configuration.allowsAirPlayForMediaPlayback)
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
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
            if let jsFromInfoDictionary = info[TagManagementKey.jsCommand] as? String,
               let payload = info[TagManagementKey.payload] as? [String: Any] {
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
        expect = expectation(description: "trackRequest")
        module = TagManagementModule(config: config, delegate: TagManagementModuleDelegate(), completion: { _ in })
        let track = TealiumTrackRequest(data: ["test_track": true])
        module?.dispatchTrack(track, completion: { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected error: \(error.localizedDescription)")
            case .success(let success):
                XCTAssertTrue(success)
                self.expect.fulfill()
            }
        })
        wait(for: [expect], timeout: 2.0)
    }

    func testDispatchTrackCreatesBatchTrackRequest() {
        expect = expectation(description: "batchTrackRequest")
        module = TagManagementModule(config: config, delegate: TagManagementModuleDelegate(), completion: { _ in })
        let track = TealiumTrackRequest(data: ["test_track": true])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track])
        module?.dispatchTrack(batchTrack, completion: { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected error: \(error.localizedDescription)")
            case .success(let success):
                XCTAssertTrue(success)
                self.expect.fulfill()
            }
        })
        wait(for: [expect], timeout: 2.0)
    }

}

@available(iOS 11.0, *)
class TagManagementModuleDelegate: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
