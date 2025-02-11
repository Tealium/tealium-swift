//
//  ResourceRetrieverTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 05/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class NoDelayRetriever<T: Codable>: ResourceRetriever<T> {
    override func delayBlock(delayMultiplier: Double, _ block: @escaping () -> Void) {
        block()
    }
}

final class ResourceRetrieverTests: XCTestCase {

    struct CustomObject: Codable, EtagResource, Equatable {
        let someString: String
        let someInt: Int
        var etag: String?
    }
    let mockUrlSession = MockURLSession()
    func getResourceRetriever() -> ResourceRetriever<CustomObject> {
        NoDelayRetriever(urlSession: mockUrlSession) { data, etag in
            var obj = try? JSONDecoder().decode(CustomObject.self, from: data)
            obj?.etag = etag
            return obj
        }
    }
    lazy var resourceRetriever = getResourceRetriever()

    func testReceiveObject() {
        let completionCalled = expectation(description: "Completion is called")
        let obj = CustomObject(someString: "aString", someInt: 2, etag: nil)
        mockUrlSession.result = .success(with: obj)
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: nil) { result in
            XCTAssertEqual(try? result.get(), obj)
            completionCalled.fulfill()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testReceiveObjectWithEtag() {
        let completionCalled = expectation(description: "Completion is called")
        var obj = CustomObject(someString: "aString", someInt: 2, etag: nil)
        mockUrlSession.result = .success(with: obj, headers: ["etag": "someEtag"])
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: nil) { result in
            obj.etag = "someEtag"
            XCTAssertEqual(try? result.get(), obj)
            completionCalled.fulfill()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testEtagIsSent() {
        let completionCalled = expectation(description: "Completion is called")
        let requestSent = expectation(description: "Request sent")
        var obj = CustomObject(someString: "aString", someInt: 2, etag: nil)
        mockUrlSession.result = .success(with: obj, headers: ["etag": "someEtag"])
        mockUrlSession.onRequestSent.subscribeOnce { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "if-none-match"), "etagSent")
            requestSent.fulfill()
        }
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: "etagSent") { result in
            obj.etag = "someEtag"
            XCTAssertEqual(try? result.get(), obj)
            completionCalled.fulfill()
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1.0)
        }
    }

    func testEmptyBody() {
        let completionCalledWithError = expectation(description: "Completion is called with error")
        mockUrlSession.result = .success(withData: nil)
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: nil) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error, TealiumResourceRetrieverError.emptyBody)
                completionCalledWithError.fulfill()
            }
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1)
        }
    }

    func testCouldNotDecodeJSON() {
        let completionCalledWithError = expectation(description: "Completion is called with error")
        mockUrlSession.result = .success(with: "")
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: nil) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error, TealiumResourceRetrieverError.couldNotDecodeJSON)
                completionCalledWithError.fulfill()
            }
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1)
        }
    }

    func test404Response() {
        let completionCalledWithError = expectation(description: "Completion is called with error")
        mockUrlSession.result = .success((HTTPURLResponse(url: URL(string:"url")!,
                                                          statusCode: 404,
                                                          httpVersion: "1.1",
                                                          headerFields: nil),
                                          data: nil))
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: nil) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error, TealiumResourceRetrieverError.non200Response(code: 404))
                completionCalledWithError.fulfill()
            }
        }
        TealiumQueues.backgroundSerialQueue.sync {
            waitForExpectations(timeout: 1)
        }
    }

    func testRetries() {
        let completionCalledWithError = expectation(description: "Completion is called with error")
        let requestSent5Times = expectation(description: "Request sent 5 times")
        requestSent5Times.expectedFulfillmentCount = 6
        mockUrlSession.result = .success((HTTPURLResponse(url: URL(string:"url")!,
                                                          statusCode: 408,
                                                          httpVersion: "1.1",
                                                          headerFields: nil),
                                          data: nil))
        mockUrlSession.onRequestSent.subscribe { request in
            print("Request Sent")
            XCTAssertEqual(request.value(forHTTPHeaderField: "if-none-match"), "etagSent")
            requestSent5Times.fulfill()
        }
        resourceRetriever.getResource(url: URL(string: "someURL")!, etag: "etagSent") { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error, TealiumResourceRetrieverError.non200Response(code: 408))
                completionCalledWithError.fulfill()
            }
        }
        waitForExpectations(timeout: 5.0)
    }
}
