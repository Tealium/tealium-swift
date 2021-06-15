//
//  TealiumCollectTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
import XCTest

class TealiumCollectTests: XCTestCase {

    let testJSONString = """
                            {\n  \"tealium_account\" : \"hello\",\n  \"tealium_environment\" : \"dev\",\n  \"tealium_profile\" : \"tester\"\n}
                            """
    let testDictionary = ["tealium_account": "hello",
                          "tealium_environment": "dev",
                          "tealium_profile": "tester"
    ]

    var mockURLSession: URLSessionProtocol!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func validTestDataDictionary() -> [String: Any] {
        return [
            TealiumKey.account: "account",
            TealiumKey.profile: "profile" ,
            TealiumKey.environment: "environment" ,
            TealiumKey.event: "test" ,
            TealiumKey.libraryName: TealiumValue.libraryName ,
            TealiumKey.libraryVersion: TealiumValue.libraryVersion ,
            TealiumKey.sessionId: "someSessionId" ,
            TealiumKey.visitorId: "someVisitorId" ,
            TealiumKey.random: "someRandomNumber"
        ]
    }

    func testInitWithBaseURLString() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectURL = "tealium"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.singleEventPath)")
    }
    
    func testInitWithValidURLOverrides() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectURL = "https://collect-eu-west-1.tealiumiq.com:445/event"
        config.overrideCollectBatchURL = "https://collect-us-east-1.tealiumiq.com:445/bulk-event"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "https://collect-eu-west-1.tealiumiq.com:445/event")
        XCTAssertEqual(dispatcher.batchEventDispatchURL, "https://collect-us-east-1.tealiumiq.com:445/bulk-event")
        
    }
    
    func testIsValidURL() {
        
        let badURLs = [
            "Collect",
            "xfdufhdugh.sdfsdfn",
            "tealium",
            "212345.6462",
            "1",
            "12",
            "127",
            "127.",
            "127.0",
            "127.0.0",
            "127.0.0.",
            "127.0.0.1:",
            "127.0.0.1:123456",
            "file:127.0.0.1",
            "html://127.0.0.1",
            "http:127.0.0.1",
            "httpd://127.0.0.1",
            "file:127.0.0.1",
            "https:127.0.0.1",
            "htmls://127.0.0.1",
            "htts://127.0.0.1",
            "hello@hello.com",
            "http://hello@hello.com",
            "http://google.com@hello",
            "file:c:test",
            "ftp://test.com/",
            "git:test.com:path/to/res.git",
            "ssh:google.com",
            "http://localhost/",
            "https://localhost/",
            "localhost",
        ]
        
        let goodUrls = [
            "collect.tealiumiq.com",
            "collect.tealiumiq.com/event",
            "collect.tealiumiq.com/bulk-event",
            "https://collect.tealiumiq.com/bulk-event",
            "https://collect-eu-west-1.tealiumiq.com/event",
            "https://collect-eu-west-1.tealiumiq.com/bulk-event",
            "http://google.com/a/b/c/d/e/f/g",
            "http://google.com/a/b/c?",
            "http://google.com/a/b/c?z=2&y=hello",
            "http://google.com/a/b/c?text=%2FHi%2F",
            "https://google.com/a/b/c/d/e/f/g",
            "https://google.com/a/b/c?",
            "https://google.com/a/b/c?z=2&y=hello",
            "https://google.com/a/b/c?text=%2FHi%2F",
            "http://google.co",
            "http://google.com",
            "http://google.co.uk",
            "http://www.google.co",
            "http://www.google.com",
            "http://www.google.co.uk",
            "http://www.google.co.uk:12345",
            "https://google.co",
            "https://google.com",
            "https://google.co.uk",
            "https://www.google.co",
            "https://www.google.com",
            "https://www.google.co.uk",
            "https://www.google.co.uk:12345",
            "myMac.local",
            "https://127.0.0.1:1",
            "https://127.0.0.1:12",
            "https://127.0.0.1:123",
            "https://127.0.0.1:1234",
            "https://127.0.0.1:12345",
            "https://127.0.0.1:12345/",
            "https://127.0.0.1:12345/a",
            "https://127.0.0.1:12345/a/",
            "https://127.0.0.1:12345/a/b",
            "https://127.0.0.1:12345/a/b?",
            "https://127.0.0.1:12345/a/b?z",
            "https://127.0.0.1:12345/a/b?z=",
            "https://127.0.0.1:12345/a/b?z=%",
            "http://127.0.0.1:1",
            "http://127.0.0.1:12",
            "http://127.0.0.1:123",
            "http://127.0.0.1:1234",
            "http://127.0.0.1:12345",
            "http://127.0.0.1:12345/",
            "http://127.0.0.1:12345/a",
            "http://127.0.0.1:12345/a/",
            "http://127.0.0.1:12345/a/b",
            "http://127.0.0.1:12345/a/b?",
            "http://127.0.0.1:12345/a/b?z",
            "http://127.0.0.1:12345/a/b?z=",
            "http://127.0.0.1:12345/a/b?z=%",
            "127.0.0.1:1",
            "127.0.0.1:12",
            "127.0.0.1:123",
            "127.0.0.1:1234",
            "127.0.0.1:12345",
            "127.0.0.1:12345/",
            "127.0.0.1:12345/a",
            "127.0.0.1:12345/a/",
            "127.0.0.1:12345/a/b",
            "127.0.0.1:12345/a/b?",
            "127.0.0.1:12345/a/b?z",
            "127.0.0.1:12345/a/b?z=",
            "127.0.0.1:12345/a/b?z=%",
            "127.0.0.1",
            "127.0.0.1/",
            "127.0.0.1/a",
            "127.0.0.1/a/",
            "127.0.0.1/a/b",
            "127.0.0.1/a/b?",
            "127.0.0.1/a/b?z",
            "127.0.0.1/a/b?z=",
            "127.0.0.1/a/b?z=%"
        ]
        
        badURLs.forEach {
            XCTAssertFalse(CollectEventDispatcher.isValidUrl($0), "Unexpected Success for url: \($0)")
        }
        
        goodUrls.forEach {
            XCTAssertTrue(CollectEventDispatcher.isValidUrl($0), "Unexpected Failure for url: \($0)")
        }
    }
    
    func testInitWithDomainOverrides() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectDomain = "my-endpoint.com"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "https://my-endpoint.com/event/")
        XCTAssertEqual(dispatcher.batchEventDispatchURL, "https://my-endpoint.com/bulk-event/")
    }
    
    func testURLOverridesTakePrecedenceOverDomain() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectDomain = "my-endpoint.com"
        config.overrideCollectURL = "https://collect-eu-west-1.tealiumiq.com/event"
        config.overrideCollectBatchURL = "https://collect-us-east-1.tealiumiq.com/bulk-event"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "https://collect-eu-west-1.tealiumiq.com/event")
        XCTAssertEqual(dispatcher.batchEventDispatchURL, "https://collect-us-east-1.tealiumiq.com/bulk-event")
    }
    
    func testInitWithValidURLOverrideSingleEvent() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectURL = "https://collect-eu-west-1.tealiumiq.com/event"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "https://collect-eu-west-1.tealiumiq.com/event")
        XCTAssertEqual(dispatcher.batchEventDispatchURL, "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.batchEventPath)")
    }
    
    func testInitWithValidURLOverrideBatchEvent() {
        // invalid url
        let config = testTealiumConfig.copy
        config.overrideCollectBatchURL = "https://collect-us-east-1.tealiumiq.com/bulk-event"
        
        let dispatcher = CollectEventDispatcher(config: config) { result in
            switch result.0 {
            case .failure(let error):
                XCTFail("Unexpected failure \(error.localizedDescription) - should revert to default URLs")
            case .success:
                break
            }
        }
        XCTAssertEqual(dispatcher.singleEventDispatchURL, "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.singleEventPath)")
        XCTAssertEqual(dispatcher.batchEventDispatchURL, "https://collect-us-east-1.tealiumiq.com/bulk-event")
    }

    func testInitWithBaseURLStringDefaultURLs() {
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig)

        guard let batchURL = dispatcher.batchEventDispatchURL else {
            XCTFail("Missing batch url")
            return
        }

        guard let url = dispatcher.singleEventDispatchURL else {
            XCTFail("Missing single event url")
            return
        }

        XCTAssertEqual(batchURL, "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.batchEventPath)")
        XCTAssertEqual(url, "\(CollectEventDispatcher.defaultDispatchBaseURL)\(CollectEventDispatcher.singleEventPath)")
    }

    func testGetURLSessionReturnsEphemeralSession() {
        let session = CollectEventDispatcher.urlSession

        XCTAssertNotEqual(session.configuration.httpCookieStorage!.debugDescription, URLSessionConfiguration.default.httpCookieStorage!.debugDescription)
        XCTAssertEqual(session.configuration.httpCookieStorage!.debugDescription, URLSessionConfiguration.ephemeral.httpCookieStorage!.debugDescription)
    }

    func testValidURL() {
        let validURL = "https://collect.tealiumiq.com/event/"
        XCTAssertTrue(CollectEventDispatcher.isValidUrl(validURL), "isValidURL returned unexpected failure")
        let invalidURL = "invalidURL"
        XCTAssertFalse(CollectEventDispatcher.isValidUrl(invalidURL), "isValidURL returned unexpected success")
    }

    func testSendURLRequest() {
        mockURLSession = MockURLSession()
        guard let request = NetworkUtils.urlPOSTRequestWithJSONString(testJSONString, dispatchURL: CollectEventDispatcher.defaultDispatchBaseURL) else {
            XCTFail("Could not create post request")
            return
        }
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.sendURLRequest(request) { result in
            switch result.0 {
            case .failure:
                XCTFail("Unexpected failure")
            case .success(let success):
                XCTAssertTrue(success)
                XCTAssertNil(result.1)
            }
        }
    }

    func testSendURLRequestFailingURL() {
        mockURLSession = MockURLSessionError()
        guard let request = NetworkUtils.urlPOSTRequestWithJSONString(testJSONString, dispatchURL: CollectEventDispatcher.defaultDispatchBaseURL) else {
            XCTFail("Could not create post request")
            return
        }
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.sendURLRequest(request) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.xErrorDetected)
                XCTAssertNotNil(result.1)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testSendURLRequestNon200() {
        mockURLSession = MockURLSessionNon200()
        guard let request = NetworkUtils.urlPOSTRequestWithJSONString(testJSONString, dispatchURL: CollectEventDispatcher.defaultDispatchBaseURL) else {
            XCTFail("Could not create post request")
            return
        }
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.sendURLRequest(request) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.non200Response)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testSendURLRequestURLError() {
        mockURLSession = MockURLSessionURLError()
        guard let request = NetworkUtils.urlPOSTRequestWithJSONString(testJSONString, dispatchURL: CollectEventDispatcher.defaultDispatchBaseURL) else {
            XCTFail("Could not create post request")
            return
        }
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.sendURLRequest(request) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual((error as! URLError).code, URLError.Code.appTransportSecurityRequiresSecureConnection)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

    func testDispatch() {
        mockURLSession = MockURLSession()
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.dispatch(data: self.testDictionary) { result in
            switch result.0 {
            case .failure:
                XCTFail("Unexpected failure")
            case .success(let success):
                XCTAssertTrue(success)
                XCTAssertNil(result.1)
            }
        }
    }

    func testDispatchWithError() {
        mockURLSession = MockURLSessionError()
        let dispatcher = CollectEventDispatcher(config: testTealiumConfig, urlSession: mockURLSession)
        dispatcher.dispatch(data: self.testDictionary) { result in
            switch result.0 {
            case .failure(let error):
                XCTAssertEqual(error as! CollectError, CollectError.xErrorDetected)
                XCTAssertNotNil(result.1)
            case .success:
                XCTFail("Unexpected success")
            }
        }
    }

}
