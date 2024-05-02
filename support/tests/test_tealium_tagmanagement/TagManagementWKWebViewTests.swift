//
//  TagManagementWKWebViewTests.swift
//  TealiumTagManagementTests-iOS
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumTagManagement
import TealiumCore
import UIKit

class TagManagementWKWebViewTests: XCTestCase {
    let testURL = TestTealiumHelper().newConfig().webviewURL
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDisableOnMainThread() throws {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view, completion: nil)
        XCTAssertEqual(view, tagManagementWV.webview?.superview)
        tagManagementWV.disable()
        XCTAssertNil(tagManagementWV.webview?.superview)
    }

    func testDisableOnBackgroundThread() throws {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view, completion: nil)
        XCTAssertEqual(view, tagManagementWV.webview?.superview)
        let expectation = XCTestExpectation()
        DispatchQueue(label: "anyQueue").async {
            tagManagementWV.disable()
            DispatchQueue.main.async {
                XCTAssertNil(tagManagementWV.webview?.superview)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3)
    }
    
    func testDeinitOnMainThread() throws {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        var tagManagementWV: TagManagementWKWebView? = TagManagementWKWebView(config: config, delegate: nil)
        weak var weakRef = tagManagementWV
        let view = UIView()
        tagManagementWV?.enable(webviewURL: testURL, delegates: nil, view: view, completion: nil)
        XCTAssertEqual(view, tagManagementWV?.webview?.superview)
        let webview = tagManagementWV?.webview
        tagManagementWV = nil
        XCTAssertNil(webview!.superview)
        XCTAssertNil(weakRef)
    }

    func testDeinitOnBackgroundThread() throws {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        var tagManagementWV: TagManagementWKWebView? = TagManagementWKWebView(config: config, delegate: nil)
        weak var weakRef = tagManagementWV
        let view = UIView()
        tagManagementWV?.enable(webviewURL: testURL, delegates: nil, view: view, completion: nil)
        XCTAssertEqual(view, tagManagementWV?.webview?.superview)
        let expectation = XCTestExpectation()
        DispatchQueue(label: "anyQueue").async {
            let webview = tagManagementWV?.webview
            tagManagementWV = nil
            DispatchQueue.main.async {
                XCTAssertNil(webview!.superview)
                XCTAssertNil(weakRef)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    @available(iOS 10.0, *)
    func testEnableDispatchQueue() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let expectation = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view) { _, error in
            XCTAssertNil(error)
            dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    @available(iOS 10.0, *)
    func testEnableDispatchQueueWithMissingURL() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let expectation = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: nil, delegates: nil, view: view) { _, error in
            XCTAssertNotNil(error)
            dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    

    @available(iOS 10.0, *)
    func testReloadDispatchQueue() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let enableComplete = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view) { _, error in
            enableComplete.fulfill()
        }
        waitForExpectations(timeout: 5)
        let expectation = expectation(description: "Reload complete")
        tagManagementWV.reload { _, _, _ in
            dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    @available(iOS 10.0, *)
    func testReloadMultipleTimesDispatchQueue() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let enableComplete = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view) { _, error in
            enableComplete.fulfill()
        }
        waitForExpectations(timeout: 5)
        let expectation = expectation(description: "Reload complete")
        expectation.expectedFulfillmentCount = 5
        for _ in 0..<5 {
            tagManagementWV.reload { _, _, _ in
                dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 3)
    }
    
    @available(iOS 10.0, *)
    func testTrackDispatchQueue() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let enableComplete = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view) { _, error in
            enableComplete.fulfill()
        }
        waitForExpectations(timeout: 5)
        let expectation = expectation(description: "Track complete")
        tagManagementWV.track(["something":"value"]) { _, _, _ in
            dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
    }

    @available(iOS 10.0, *)
    func testTrackMultipleDispatchQueue() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let view = UIView()
        let enableComplete = expectation(description: "Enable complete")
        tagManagementWV.enable(webviewURL: testURL, delegates: nil, view: view) { _, error in
            enableComplete.fulfill()
        }
        waitForExpectations(timeout: 5)
        let expectation = expectation(description: "TrackMultiple complete")
        tagManagementWV.trackMultiple([["something":"value"], ["somethingelse": "value"]]) { _, _, _ in
            dispatchPrecondition(condition: .onQueueAsBarrier(TealiumQueues.backgroundSerialQueue))
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
    }
    
    @available(iOS 10.0, *)
    func testGetWebViewBeforeSetup() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let expect = expectation(description: "Webview is returned when called before the setup")
        tagManagementWV.getWebView { webView in
            expect.fulfill()
            dispatchPrecondition(condition: .onQueue(.main))
        }
        tagManagementWV.setupWebview(forURL: URL(string: "https://www.tealium.com"), withSpecificView: nil)
        waitForExpectations(timeout: 3.0)
    }
    
    @available(iOS 10.0, *)
    func testGetWebViewAfterSetup() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let expect = expectation(description: "Webview is returned when called after the setup")
        tagManagementWV.setupWebview(forURL: URL(string: "https://www.tealium.com"), withSpecificView: nil)
        tagManagementWV.getWebView { webView in
            expect.fulfill()
            dispatchPrecondition(condition: .onQueue(.main))
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func testGetWebViewDontReturnWithoutSetup() {
        let config = testTealiumConfig.copy
        config.dispatchers = [Dispatchers.TagManagement]
        let tagManagementWV = TagManagementWKWebView(config: config, delegate: nil)
        let expect = expectation(description: "Webview is never returned if webview is not setup")
        expect.isInverted = true
        tagManagementWV.getWebView { webView in
            expect.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }
}
