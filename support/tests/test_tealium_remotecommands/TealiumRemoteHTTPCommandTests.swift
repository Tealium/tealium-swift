//
//  TealiumRemoteHTTPCommandTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/30/17.
//  Copyright © 2017 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumRemoteHTTPCommandTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHTTPRequestGET() {
        // TODO: Make this test more dynamic
        let scheme = "tealium"
        let commandId = "test"
        let url = "\(scheme)://\(commandId)"
        let method = "GET"
        let username = "testUsername"
        let password = "testPassword"
        let headers = ["a": "b",
                       "c": "d"]
        let params = ["1": "2",
                      "3": "4",
                      "a": ["a1", "a2", "a3"]] as [String: Any]
        let body = ["a1k": "a1v"]
        let payload: [String: Any] = ["authenticate": ["username": username,
                                                       "password": password],
                                      "url": url,
                                      "headers": headers,
                                      "parameters": params,
                                      "body": body,
                                      "method": method]
        let result = TealiumRemoteHTTPCommand.httpRequest(payload: payload)
        XCTAssertTrue(result.error == nil, "Unexpected error: \(String(describing: result.error))")

        guard let request = result.request else {
            XCTFail("No request from process.")
            return
        }
        guard let requestUrl = request.url else {
            XCTFail("No url from process.")
            return
        }

        // request
        //  allHTTPHeaderFields=["Authorization":"Basic (hash)", "Content-Type":"applciation/json; charset=utf-8", "a":"b", "c":"d"]
        //  httpbody = nil
        //  httpMethod = GET
        //  url = tealium://test?1=2&3=4

        let expectedHeaderFields: [String: String] = ["Authorization": "Basic dGVzdFVzZXJuYW1lOnRlc3RQYXNzd29yZA==",
                                    "Content-Type": "application/json; charset=utf-8",
                                    "a": "b",
                                    "c": "d"]
        let returnedHeaderFields = request.allHTTPHeaderFields!

        XCTAssertTrue(expectedHeaderFields == returnedHeaderFields, "Unexpected result from returned header fields: \(returnedHeaderFields)")
        XCTAssertTrue(request.httpMethod == method, "Unexpected method type:\(String(describing: request.httpMethod))")
        let expectedUrl = "\(scheme)://\(commandId)?1=2&3=4&a=%5B%22a1%22,%20%22a2%22,%20%22a3%22%5D"   // Being lazy here
        XCTAssertTrue(expectedUrl == request.url?.absoluteString, "Unexpected request url: \(String(describing: request.url?.absoluteString))")

        // requestUrl
        //  scheme = tealium
        //  host = test
        //  password=nil
        //  user=nil,

        XCTAssertTrue(requestUrl.scheme == scheme, "Unexpected scheme: \(String(describing: requestUrl.scheme))")
        XCTAssertTrue(requestUrl.host == commandId, "Unexpected commandId:\(String(describing: requestUrl.host))")
    }

    func testParamItemsFromDictionary() {
        let params: [String: Any] = ["1": 2,
                                    "a": "b",
                                    "array": ["x", "y", "z"]
                                    ]

        let queryItems = TealiumRemoteHTTPCommand.paramItemsFrom(dictionary: params)

        let itemA = URLQueryItem(name: "1", value: "2")
        let itemB = URLQueryItem(name: "a", value: "b")
        let itemC = URLQueryItem(name: "array", value: "[\"x\", \"y\", \"z\"]")

        let expectedQueryItems = [itemA,
                                  itemB,
                                  itemC]

        XCTAssertTrue(expectedQueryItems == queryItems, "Unexpected query items returned: \(queryItems), expected: \(expectedQueryItems)")
    }

}
