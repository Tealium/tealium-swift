//
//  TealiumRemoteHTTPCommandTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 3/30/17.
//  Copyright © 2017 tealium. All rights reserved.
//

import XCTest

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
        
        let host = "tealium"
        let commandId = "test"
        let url = "\(host)://\(commandId)"
        let method = "GET"
        let username = "testUsername"
        let password = "testPassword"
        let headers = ["a":"b",
                       "c":"d"]
        let params = ["1":"2",
                      "3":"4"]
        let body = ["a1k":"a1v"]
        let payload : [String:Any] = ["authenticate": ["username":username,
                                                       "password":password],
                                      "url":url,
                                      "headers":headers,
                                      "parameters":params,
                                      "body":body,
                                      "method":method]
        let result = TealiumRemoteHTTPCommand.httpRequest(payload: payload)
        XCTAssertTrue(result.error == nil, "Unexpected error: \(result.error)")

        guard let request = result.request else {
            XCTFail("No request from process.")
            return
        }
        guard let requestUrl = request.url else {
            XCTFail("No url from process.")
            return
        }
        XCTAssertTrue(requestUrl.scheme == host, "Unexpected scheme: \(requestUrl.scheme)")
        
        XCTFail()
//        XCTAssertTrue(requestUrl.path == commandId, "Unexpected commandId:\(requestUrl.path)")
//        XCTAssertTrue(requestUrl.user == username, "Unexpected user returned.")
//        XCTAssertTrue(requestUrl.password == password, "Unexpected password returned.")
        
    }
    
    func testParamItemsFromDictionary() {
        
        XCTFail()

    }
    
    func testCompletionNotification() {
        XCTFail()

    }
    
}
