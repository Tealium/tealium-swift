//
//  URLResponseTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 14/04/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

final class URLResponseTests: XCTestCase {
    let etagValue = "\"someEtag\""
    
    func testEtagLowercase() {
        let urlResponse = urlResponse(["etag": etagValue])
        let etag = urlResponse.etag
        XCTAssertEqual(etag, etagValue)
    }
    
    func testEtagUpperCase() {
        let urlResponse = urlResponse(["ETAG": etagValue])
        let etag = urlResponse.etag
        XCTAssertEqual(etag, etagValue)
    }
    
    func testEtagCapitalized() {
        let urlResponse = urlResponse(["Etag": etagValue])
        let etag = urlResponse.etag
        XCTAssertEqual(etag, etagValue)
    }
    
    func testHeaderString() {
        let urlResponse = urlResponse(["etAg": etagValue])
        XCTAssertEqual(urlResponse.headerString(field: "etag"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "Etag"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "eTag"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "etAg"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "etaG"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "EtAg"), etagValue)
        XCTAssertEqual(urlResponse.headerString(field: "ETAG"), etagValue)
    }
    
    func urlResponse(_ headerFields: [String: String]) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://www.google.com")!, statusCode: 200, httpVersion: "2.0", headerFields: headerFields)!
    }
}
