//
//  PublishSettingsTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

private let settingsUrl = URL(string:"https://tags.tiqcdn.com/utag/tealiummobile/demo/dev/mobile.html")!

class PublishSettingsTests: XCTestCase {
    static var delegateExpectationSuccess: XCTestExpectation?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGetPublishSettingsFromJSON() {
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true
        let string = """
        <!--tealium tag management - mobile.webview ut4.0.202001151447, Copyright 2020 Tealium.com Inc. All Rights Reserved.-->
        <html>
        <head><title>Tealium Mobile Webview</title></head>
        <body>
        <script type="text/javascript">var utag_cfg_ovrd={noview:true};var mps = {"4":{"_is_enabled":"false","battery_saver":"false","dispatch_expiration":"-1","event_batch_size":"1","ivar_tracking":"false","mobile_companion":"false","offline_dispatch_limit":"-1","ui_auto_tracking":"false","wifi_only_sending":"false"},"5":{"_is_enabled":"true","battery_saver":"false","dispatch_expiration":"-1","enable_collect":"true","enable_s2s_legacy":"false","enable_tag_management":"true","event_batch_size":"4","minutes_between_refresh":"1.0","offline_dispatch_limit":"30","override_log":"dev","wifi_only_sending":"true"},"_firstpublish":"true"}</script>
        <script type="text/javascript" src="//tags.tiqcdn.com/utag/tealiummobile/demo/dev/utag.js"></script>
        </body>
        </html>

        """
        let data = string.data(using: .utf8)
        let publishSettings = TealiumPublishSettingsRetriever.getPublishSettings(from: data!, etag: nil)
        XCTAssertEqual(publishSettings?.batchSize, 4, "Batch size incorrect")
        XCTAssertEqual(publishSettings?.dispatchExpiration, -1, "Batch size incorrect")
        XCTAssertEqual(publishSettings?.wifiOnlySending, true, "Batch size incorrect")
        XCTAssertEqual(publishSettings?.isEnabled, true, "Batch size incorrect")
        XCTAssertEqual(publishSettings?.batterySaver, false, "Battery saver enabled")
        XCTAssertEqual(publishSettings?.collectEnabled, true, "Collect not enabled")
        XCTAssertEqual(publishSettings?.tagManagementEnabled, true, "Tag management not enabled")
        XCTAssertEqual(publishSettings?.minutesBetweenRefresh, 1.0, "Minutes between refresh incorrect")
        XCTAssertEqual(publishSettings?.dispatchQueueLimit, 30, "Dispatch queue limit incorrect")
        //XCTAssertEqual(publishSettings?.overrideLog, .verbose, "Log level incorrect")
    }

    func testGetRemoteSettings() {
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true

        let publishSettingsRetriever = TealiumPublishSettingsRetriever(config: config,
                                                                       diskStorage: MockTealiumDiskStorage(),
                                                                       urlSession: MockURLSessionPublishSettings(),
                                                                       delegate: self)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertNotNil(publishSettingsRetriever.cachedSettings)
        }
    }

    func testGetRemoteSettingsExtraContent() {
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true

        let publishSettingsRetriever = TealiumPublishSettingsRetriever(config: config,
                                                                       diskStorage: MockTealiumDiskStorage(),
                                                                       urlSession: MockURLSessionPublishSettingsExtraContent(),
                                                                       delegate: self)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertNotNil(publishSettingsRetriever.cachedSettings)
        }
    }

    func testGetRemoteSettingsNoContent() {
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true

        let publishSettingsRetriever = TealiumPublishSettingsRetriever(config: config,
                                                                       diskStorage: MockTealiumDiskStorage(),
                                                                       urlSession: MockURLSessionPublishSettingsNoContent(),
                                                                       delegate: self)
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertNil(publishSettingsRetriever.cachedSettings)
        }
    }
    
    func testGetRemoteSettingsRefreshesWithLatestEtag() {
        PublishSettingsTests.delegateExpectationSuccess = self.expectation(description: "publishsettings")
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true
        let urlSession = MockURLSessionPublishSettings()
        let delegate = GetSavePublishSettings()
        let publishSettingsRetriever = TealiumPublishSettingsRetriever(config: config,
                                                                       diskStorage: MockTealiumDiskStorage(),
                                                                       urlSession: urlSession,
                                                                       delegate: delegate)
        let firstUrlRequest = self.expectation(description: "first urlRequest arrived")
        urlSession.onURLRequest.subscribeOnce { req in
            XCTAssertNil(req.allHTTPHeaderFields?["If-None-Match"])
            firstUrlRequest.fulfill()
        }
        wait(for: [PublishSettingsTests.delegateExpectationSuccess!], timeout: 5.0)
        PublishSettingsTests.delegateExpectationSuccess = nil
        XCTAssertNotNil(publishSettingsRetriever.cachedSettings?.etag)
        publishSettingsRetriever.refresh()
        let secondUrlRequest = self.expectation(description: "second urlRequest arrived")
        TealiumQueues.backgroundSerialQueue.sync {
            urlSession.onURLRequest.subscribeOnce { req in
                XCTAssertNotNil(req.allHTTPHeaderFields?["If-None-Match"])
                XCTAssertEqual(req.allHTTPHeaderFields?["If-None-Match"], publishSettingsRetriever.cachedSettings?.etag)
                secondUrlRequest.fulfill()
            }
            waitForExpectations(timeout: 5.0)
        }
    }
    

    func testGetAndSave() {
        PublishSettingsTests.delegateExpectationSuccess = self.expectation(description: "publishsettings")
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true
        let delegate = GetSavePublishSettings()
        let retriever = TealiumPublishSettingsRetriever(config: config, diskStorage: MockTealiumDiskStorage(), urlSession: MockURLSessionPublishSettings(), delegate: delegate)
        XCTAssertNil(retriever.cachedSettings)
        TealiumQueues.backgroundSerialQueue.sync {
            wait(for: [PublishSettingsTests.delegateExpectationSuccess!], timeout: 1)
        }
    }

    
    func testMultipleRefreshDontRefreshMultipleTimes() {
        PublishSettingsTests.delegateExpectationSuccess = self.expectation(description: "publishsettings")
        PublishSettingsTests.delegateExpectationSuccess?.assertForOverFulfill = true
        let config = testTealiumConfig.copy
        config.shouldUseRemotePublishSettings = true
        let delegate = GetSavePublishSettings()
        let session = MockURLSessionPublishSettings()
        session.refreshInterval = 5
        let retriver = TealiumPublishSettingsRetriever(config: config,
                                                       diskStorage: MockTealiumDiskStorage(),
                                                       urlSession: session,
                                                       delegate: delegate)
        TealiumQueues.backgroundSerialQueue.sync {
            retriver.refresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            wait(for: [PublishSettingsTests.delegateExpectationSuccess!], timeout: 1)
        }
    }

}

extension PublishSettingsTests: TealiumPublishSettingsDelegate {
    func didUpdate(_ publishSettings: RemotePublishSettings) {

    }

}

class GetSavePublishSettings: TealiumPublishSettingsDelegate {
    func didUpdate(_ publishSettings: RemotePublishSettings) {
        PublishSettingsTests.delegateExpectationSuccess?.fulfill()
    }

}
