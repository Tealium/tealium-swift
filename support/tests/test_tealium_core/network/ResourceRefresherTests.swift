//
//  ResourceRefresherTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

final class ResourceRefresherTests: XCTestCase {
    struct CustomObject: Codable, EtagResource, Equatable {
        let someString: String
        let someInt: Int
        var etag: String?
    }
    let mockUrlSession = MockURLSession()
    let diskStorage = MockTealiumDiskStorage()
    func getResourceRetriever() -> ResourceRetriever<CustomObject> {
        ResourceRetriever(urlSession: mockUrlSession) { data, etag in
            var obj = try? JSONDecoder().decode(CustomObject.self, from: data)
            obj?.etag = etag
            return obj
        }
    }
    var refreshParameters = RefreshParameters<CustomObject>(id: "id",
                                                            url: URL(string: "url")!,
                                                            fileName: nil,
                                                            refreshInterval: 1.0)
    lazy var resourceRetriever = getResourceRetriever()
    lazy var refresher = ResourceRefresher(resourceRetriever: resourceRetriever,
                                           diskStorage: diskStorage,
                                           refreshParameters: refreshParameters)
    
    func testStartsEmpty() {
        mockUrlSession.result = .success(with: nil)
        XCTAssertNil(refresher.readResource())
    }

    func testShouldRefreshAtStart() {
        mockUrlSession.result = .success(with: nil)
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func testRequestsResource() {
        let requestSent = expectation(description: "Request is sent")
        mockUrlSession.result = .success(with: CustomObject(someString: "aString", someInt: 2))
        mockUrlSession.onRequestSent.subscribeOnce { _ in
            requestSent.fulfill()
        }
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testResourceIsStored() {
        let obj = CustomObject(someString: "aString", someInt: 2)
        mockUrlSession.result = .success(with: obj)
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(refresher.readResource(), obj)
        }
    }
    
    func testUpdatedResourceIsReportedToDelegate() {
        
    }

    func testNotModifiedResourceIsNotReportedToDelegate() {
        
    }

    func testFailedRequestIsReportedToDelegate() {
        
    }
    
    func testRequestRefreshIsIgnoredWhenInTimeout() {
        
    }

    func testRequestRefreshIsIgnoredWhenInErrorCooldown() {
        
    }

    func testErrorCooldownIncreasesForSubsequentErrors() {
        
    }
}
