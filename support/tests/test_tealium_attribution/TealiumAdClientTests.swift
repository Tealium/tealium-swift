//
//  TealiumAdClientTests.swift
//  TealiumAttributionTests-iOS
//
//  Created by Tyler Rister on 12/16/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable
import TealiumAttribution

let httpAdClientData = """
{
  "attribution": true,
  "orgId": 40669820,
  "campaignId": 542370539,
  "conversionType": "downloads",
  "adGroupId": 542317095,
  "countryOrRegion": "US",
  "keywordId": 87675432,
  "adId": 542317136
}
"""

class TealiumAdClientTests: XCTestCase {
    
    @available(iOS 14.3, *) // Needed otherwise the client always returns nil
    func testHttpAdClient() {
        let adClient = TealiumHTTPAdClient()
        let jsonData = httpAdClientData.data(using: .utf8)
        guard let jsonData = jsonData else {
            XCTFail("Invalid json data")
            return
        }
        guard let data = try? JSONSerialization.jsonObject(with: jsonData) as? [String: NSObject] else {
            XCTFail("Unable to decode json")
            return
        }
        let persistentData = adClient.getAttributionData(details: data)
        XCTAssertEqual(persistentData?.orgId, "40669820")
        XCTAssertEqual(persistentData?.campaignId, "542370539")
        XCTAssertEqual(persistentData?.conversionType, "downloads")
        XCTAssertEqual(persistentData?.adGroupId, "542317095")
        XCTAssertEqual(persistentData?.region, "US")
        XCTAssertEqual(persistentData?.adKeyword, "87675432")
        XCTAssertEqual(persistentData?.adId, "542317136")
        XCTAssertEqual(persistentData?.clickedWithin30D, "1")
    }
}
