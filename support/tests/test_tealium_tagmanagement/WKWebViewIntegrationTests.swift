//
//  WKWebViewIntegrationTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumTagManagement
import WebKit
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
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, shouldAddCookieObserver: true, view: nil) { _, _ in
            XCTAssertNotNil(self.tagManagementWKWebView.webview, "Webview instance was unexpectedly nil")
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5.0)
    }

    func testDisableWebView() {
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, shouldAddCookieObserver: true, view: nil, completion: nil)
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
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, shouldAddCookieObserver: true, view: nil, completion: nil)
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
        tagManagementWKWebView.enable(webviewURL: testURL, delegates: nil, shouldAddCookieObserver: true, view: nil) { _, _ in
            XCTAssertTrue(self.tagManagementWKWebView.isWebViewReady, "Webview should be ready, but was found to be nil")
            self.tagManagementWKWebView.webviewStateDidChange(.loadFailure, withError: nil)
            XCTAssertFalse(self.tagManagementWKWebView.isWebViewReady, "Webview should not be ready - failure condition expected")
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5.0)
    }

    func testJavaScriptTrackCall() {
        let data: [String: Any] = ["test_track": "track me"]
        let dataString = """
                        {\n  "test_track" : "track me"\n}
                        """
        let expectedJS = "utag.track(\'link\',\(dataString))"
        if let actualJS = data.tealiumJavaScriptTrackCall {
            XCTAssertEqual(expectedJS, actualJS, "")
        }
    }

    func testGetSetHasMigrated() {
        tagManagementWKWebView.setHasMigrated(userDefaults: userDefaults)
        // manual check of userDefaults
        if let hasMigrated = userDefaults?.bool(forKey: "com.tealium.tagmanagement.cookiesMigrated") {
            XCTAssertTrue(hasMigrated, "Migration flag was not set correctly")
            // API check of userDefaults
            XCTAssertTrue(tagManagementWKWebView.getHasMigrated(userDefaults: userDefaults), "GetHasMigrated should return true")
        } else {
            XCTFail("Migrated flag not found in userDefaults")
        }
    }

    // integration test - tests setting cookies on real webview
    func testMigrateCookies() {
        let expectation = self.expectation(description: "testMigrateCookies")
        let myCookieStorage = MyCookieStorage.shared
        WKWebsiteDataStore.default().httpCookieStore.add(self)
        let config = WKWebViewConfiguration()
        // we don't want persistent cookies interfering with the test
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        let webview = WKWebView(frame: .zero, configuration: config)
        tagManagementWKWebView.migrateCookies(forWebView: webview, withCookieProvider: myCookieStorage, userDefaults: userDefaults) {
            webview.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                cookies.forEach { cookie in
                    XCTAssertEqual(cookie.name, "test", "Expected cookie could not be found")
                    expectation.fulfill()
                }
            }
        }
        self.wait(for: [expectation], timeout: 5.0)
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

class MyCookieStorage: TealiumCookieProvider {
    static var shared: TealiumCookieProvider = MyCookieStorage()

    public var cookies: [HTTPCookie]? = [HTTPCookie]()

    private init() {
        let cookie = HTTPCookie(properties: [
            .domain: "https://tags.tiqcdn.com",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: "test",
            HTTPCookiePropertyKey.value: "test",
            HTTPCookiePropertyKey.secure: "TRUE",
            HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: TimeInterval(60 * 60 * 24 * 365))
        ])
        if let cookie = cookie {
            cookies?.append(cookie)
        }
    }
}

@available(iOS 11.0, *)
extension WKWebViewIntegrationTests: WKHTTPCookieStoreObserver {
    public func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        DispatchQueue.main.async {
            cookieStore.getAllCookies { _ in
                // this exists purely to work around an issue where cookies are not properly synced to WKWebView instances
                print("Cookie Monster")
            }
        }
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
