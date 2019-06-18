//
//  WKWebViewTests.swift
//  tealium-swift-tests-ios
//
//  Created by Craig Rouse on 04/02/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import Tealium
import WebKit
import XCTest

class WKWebViewTests: XCTestCase {

    let tagManagementWKWebView = TealiumTagManagementWKWebView()
    let testURL = TestTealiumHelper().newConfig().webviewURL()
    let userDefaults = UserDefaults(suiteName: #file)

    override func setUp() {
        super.setUp()
        userDefaults?.removePersistentDomain(forName: #file)
    }

    func testWKWebViewInstance() {
        XCTAssertNotNil(tagManagementWKWebView, "Webview class unexpectedly nil")
        XCTAssertNil(tagManagementWKWebView.webview, "WKWebView instance should not be initialized until enable call")
        XCTAssertEqual(tagManagementWKWebView.isWebViewReady(), false, "Webview was unexpectedly initialized")
    }

    func testEnableWebView() {
        tagManagementWKWebView.enable(webviewURL: testURL, shouldMigrateCookies: false, delegates: nil, view: nil, completion: nil)
        XCTAssertNotNil(tagManagementWKWebView.webview, "Webview instance was unexpectedly nil")
    }

    func testDisableWebView() {
        tagManagementWKWebView.enable(webviewURL: testURL, shouldMigrateCookies: false, delegates: nil, view: nil, completion: nil)
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
        tagManagementWKWebView.enable(webviewURL: testURL, shouldMigrateCookies: false, delegates: nil, view: nil, completion: nil)
        tagManagementWKWebView.track(data) { _, info, error in
            XCTAssertNil(error, "Error returned from track call")
            if let jsFromInfoDictionary = info[TealiumTagManagementKey.jsCommand] as? String,
            let payload = info[TealiumTagManagementKey.payload] as? [String: Any] {
                XCTAssertEqual(expectedJS, jsFromInfoDictionary, "Track call contained invalid data")
                XCTAssertEqual(data.description, payload.description, "Data and Payload should be equal")
                expectation.fulfill()
            }
        }
        self.wait(for: [expectation], timeout: 5.0)
    }

    func testWebViewStateDidChange() {
        XCTAssertFalse(tagManagementWKWebView.isWebViewReady(), "Webview Ready check should not be true yet")
        tagManagementWKWebView.webviewStateDidChange(.loadSuccess, withError: nil)
        XCTAssertFalse(tagManagementWKWebView.isWebViewReady(), "Webview should not be ready yet; webview has not been enabled")
        tagManagementWKWebView.enable(webviewURL: testURL, shouldMigrateCookies: false, delegates: nil, view: nil, completion: nil)
        XCTAssertTrue(tagManagementWKWebView.isWebViewReady(), "Webview should be ready, but was found to be nil")
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
            XCTAssertTrue(tagManagementWKWebView.getHasMigrated(userDefaults: userDefaults) ?? false, "GetHasMigrated should return true")
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
        HTTPCookiePropertyKey.expires: NSDate(timeIntervalSinceNow: TimeInterval(60 * 60 * 24 * 365)),
        ])
        if let cookie = cookie {
            cookies?.append(cookie)
        }
    }
}

extension WKWebViewTests: WKHTTPCookieStoreObserver {
    public func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        DispatchQueue.main.async {
            cookieStore.getAllCookies { _ in
                // this exists purely to work around an issue where cookies are not properly synced to WKWebView instances
                print("Cookie Monster")
            }
        }
    }
}
