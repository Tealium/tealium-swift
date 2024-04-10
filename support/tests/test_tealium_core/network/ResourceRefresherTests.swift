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
    
    func getRefresher(errorCooldown: ErrorCooldown? = nil) -> ResourceRefresher<CustomObject> {
        ResourceRefresher(resourceRetriever: resourceRetriever,
                          diskStorage: diskStorage,
                          refreshParameters: refreshParameters,
                          errorCooldown: errorCooldown)
    }
    var refreshParameters = RefreshParameters<CustomObject>(id: "id",
                                                            url: URL(string: "url")!,
                                                            fileName: nil,
                                                            refreshInterval: 10.0,
                                                            errorCooldownBaseInterval: 10)
    lazy var resourceRetriever = getResourceRetriever()
    lazy var refresher = getRefresher()
    
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

    func testCachedResourceIsReportedToDelegate() {
        let cachedResourceLoaded = expectation(description: "Cached resource is loaded")
        let obj = CustomObject(someString: "aString", someInt: 2)
        diskStorage.storedData = AnyCodable(obj)
        let delegate = RefresherDelegate()
        delegate.onDidLoadResource.subscribeOnce { loadedObj in
            cachedResourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, obj)
        }
        refresher.delegate = delegate
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func testUpdatedResourceIsReportedToDelegate() {
        let updatedResourceLoaded = expectation(description: "Updated resource is loaded")
        let obj = CustomObject(someString: "aString", someInt: 2)
        mockUrlSession.result = .success(with: obj)
        let delegate = RefresherDelegate()
        delegate.onDidLoadResource.subscribeOnce { loadedObj in
            updatedResourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, obj)
        }
        refresher.delegate = delegate
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testNotModifiedResourceIsReportedToFailedToLoadDelegate() {
        let updatedResourceLoadedNotCalled = expectation(description: "Updated resource is not loaded")
        updatedResourceLoadedNotCalled.isInverted = true
        let failedToLoad = expectation(description: "Resource failed to load")
        mockUrlSession.result = .success(with: nil, statusCode: 304)
        let delegate = RefresherDelegate()
        delegate.onDidLoadResource.subscribeOnce { loadedObj in
            updatedResourceLoadedNotCalled.fulfill()
        }
        delegate.onDidFailToLoadResource.subscribeOnce { error in
            failedToLoad.fulfill()
            XCTAssertEqual(error, .non200Response(code: 304))
        }
        refresher.delegate = delegate
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testFailedRequestIsReportedToDelegate() {
        let updatedResourceLoadedNotCalled = expectation(description: "Updated resource is not loaded")
        updatedResourceLoadedNotCalled.isInverted = true
        let failedToLoad = expectation(description: "Resource failed to load")
        mockUrlSession.result = .success(with: nil)
        let delegate = RefresherDelegate()
        delegate.onDidLoadResource.subscribeOnce { loadedObj in
            updatedResourceLoadedNotCalled.fulfill()
        }
        delegate.onDidFailToLoadResource.subscribeOnce { error in
            failedToLoad.fulfill()
            XCTAssertEqual(error, .emptyBody)
        }
        refresher.delegate = delegate
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }
    
    func testRequestRefreshIsIgnoredWhenInTimeout() {
        let requestSent = expectation(description: "Request is sent only once")
        mockUrlSession.result = .success(with: CustomObject(someString: "aString", someInt: 2))
        mockUrlSession.onRequestSent.subscribe { _ in
            requestSent.fulfill()
        }
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testRequestRefreshIsIgnoredWhenInErrorCooldown() {
        let requestSent = expectation(description: "Request is sent only once")
        mockUrlSession.result = .success(with: nil)
        mockUrlSession.onRequestSent.subscribe { _ in
            requestSent.fulfill()
        }
        refreshParameters = RefreshParameters(id: refreshParameters.id,
                                              url: refreshParameters.url,
                                              fileName: refreshParameters.fileName,
                                              refreshInterval: 0,
                                              errorCooldownBaseInterval: refreshParameters.errorCooldownBaseInterval)
        let errorCooldown = ErrorCooldown(baseInterval: 10, maxInterval: 50)
        refresher = getRefresher(errorCooldown: errorCooldown)
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            XCTAssertEqual(refresher.isFileCached, false)
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testRequestRefreshIsNotIgnoredAfterErrorsWhenErrorCooldownIsNil() {
        let requestSent = expectation(description: "Request is sent every time")
        requestSent.expectedFulfillmentCount = 3
        refreshParameters = RefreshParameters(id: refreshParameters.id,
                                              url: refreshParameters.url,
                                              fileName: refreshParameters.fileName,
                                              refreshInterval: 0,
                                              errorCooldownBaseInterval: nil)
        mockUrlSession.result = .success(with: nil)
        mockUrlSession.onRequestSent.subscribe { _ in
            requestSent.fulfill()
        }
        refresher.setRefreshInterval(0)
        refresher.requestRefresh()
        TealiumQueues.backgroundSerialQueue.sync {
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            refresher.requestRefresh()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }
    
    class RefresherDelegate: ResourceRefresherDelegate {
        typealias Resource = CustomObject
        @ToAnyObservable<TealiumReplaySubject<CustomObject>>(TealiumReplaySubject<CustomObject>())
        var onDidLoadResource: TealiumObservable<CustomObject>
        @ToAnyObservable<TealiumReplaySubject<TealiumResourceRetrieverError>>(TealiumReplaySubject<TealiumResourceRetrieverError>())
        var onDidFailToLoadResource: TealiumObservable<TealiumResourceRetrieverError>
        
        func resourceRefresher(_ refresher: ResourceRefresher<CustomObject>, didLoad resource: CustomObject) {
            _onDidLoadResource.publish(resource)
        }
        func resourceRefresher(_ refresher: ResourceRefresher<Resource>, didFailToLoadResource error: TealiumResourceRetrieverError) {
            _onDidFailToLoadResource.publish(error)
        }
    }
}


