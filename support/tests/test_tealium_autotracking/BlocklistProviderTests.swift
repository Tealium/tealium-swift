//
//  BlocklistProviderTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/02/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore
@testable import TealiumAutotracking

class MockProviderDelegate: ItemsProviderDelegate {
    @ToAnyObservable<TealiumReplaySubject<[String]>>(TealiumReplaySubject<[String]>())
    var blocklist: TealiumObservable<[String]>

    func didLoadItems(_ blocklist: [String]) {
        _blocklist.publish(blocklist)
    }
}

final class BlocklistProviderTests: XCTestCase {
    typealias BlocklistFile = ItemsFile<String>
    let config = {
        let config = TealiumConfig(account: "test", profile: "test", environment: "dev")
        config.autoTrackingBlocklistURL = "someUrl"
        return config
    }()
    let urlSession = MockURLSession()
    lazy var diskStorage = MockTealiumDiskStorage()
    lazy var provider = BlocklistProvider(config: config,
                                         bundle: Bundle(for: type(of: self)),
                                         urlSession: urlSession,
                                         diskStorage: diskStorage)
    static let blocklist = ["123", "456"]

    func testBlocklistLoaded() {
        let blocklistLoaded = expectation(description: "blocklist loaded")

        urlSession.result = .success(with: Self.blocklist, statusCode: 200)
        let delegate = MockProviderDelegate()
        delegate.$blocklist.subscribe { result in
            XCTAssertEqual(result, Self.blocklist)
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testBlocklistLoadedEmptyWhenRequestFails() {
        let blocklistLoaded = expectation(description: "blocklist loaded")

        urlSession.result = .success(withData: Data(), statusCode: 404)
        let delegate = MockProviderDelegate()
        delegate.$blocklist.subscribe { result in
            XCTAssertEqual(result, [])
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testBlocklistLoadedFromCacheWhenAvailable() {
        let blocklistLoaded = expectation(description: "blocklist loaded")
        // 429 causes retries so won't report immediately in the refresher
        urlSession.result = .success(withData: Data(), statusCode: 429)
        let file = BlocklistFile(etag: nil, items: Self.blocklist)
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: BlocklistFile.self), file)
        let delegate = MockProviderDelegate()
        delegate.$blocklist.subscribe { result in
            XCTAssertEqual(result, Self.blocklist)
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    // Test cached + remote success
    func testBlocklistLoadedFromCacheWhenAvailableAndUpdatedFromRemote() {
        let blocklistLoaded = expectation(description: "blocklist loaded")
        blocklistLoaded.expectedFulfillmentCount = 2
        urlSession.result = .success(with: Self.blocklist, statusCode: 200)
        let file = BlocklistFile(etag: nil, items: [])
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: BlocklistFile.self), file)
        let delegate = MockProviderDelegate()
        var count = 0
        delegate.$blocklist.subscribe { result in
            if count == 0 {
                XCTAssertEqual(result, [])
            } else {
                XCTAssertEqual(result, Self.blocklist)
            }
            count += 1
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testBlocklistLoadedFromCacheWhenAvailableAndFailsFromRemote() {
        let blocklistLoaded = expectation(description: "blocklist loaded")
        urlSession.result = .success(withData: Data(), statusCode: 404)
        let file = BlocklistFile(etag: nil, items: Self.blocklist)
        diskStorage.save(file) { _,_,_ in }
        XCTAssertEqual(diskStorage.retrieve(as: BlocklistFile.self), file)
        let delegate = MockProviderDelegate()
        delegate.$blocklist.subscribe { result in
            XCTAssertEqual(result, Self.blocklist)
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }

    func testLocalBlocklistFile() {
        let blocklistLoaded = expectation(description: "blocklist loaded")
        config.autoTrackingBlocklistFilename = "blocklist"
        let expected = ["blocked"]
        urlSession.result = .success(with: Self.blocklist, statusCode: 200)
        let delegate = MockProviderDelegate()
        delegate.$blocklist.subscribe { result in
            XCTAssertEqual(result, expected)
            blocklistLoaded.fulfill()
        }
        provider.loadItems(delegate: delegate)
        waitForExpectations(timeout: 0.1)
    }
}
