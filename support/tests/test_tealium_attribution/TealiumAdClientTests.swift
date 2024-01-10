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

let adClientData = """
{
    "Version3.1": {
        "iad-adgroup-id": "1234567890",
        "iad-adgroup-name": "add-group",
        "iad-attribution": "true",
        "iad-campaign-id": "1234567890",
        "iad-campaign-name": "Campaign Name",
        "iad-click-date": "2018-06-12T14:56:14Z",
        "iad-conversion-date": "2018-06-12T14:56:14Z",
        "iad-creativeset-id": "1234567890",
        "iad-creativeset-name": "Creative Name",
        "iad-keyword": "Keyword",
        "iad-org-name": "Org Name"
    }
}
"""

class TealiumAdClientTests: XCTestCase {
    
    func testAdClient() {
        let adClient = TealiumAdClient()
        let jsonData = adClientData.data(using: .utf8)
        guard let jsonData = jsonData else {
            XCTFail("Invalid json data")
            return
        }
        guard let data = try? JSONSerialization.jsonObject(with: jsonData) as? [String: NSObject] else {
            XCTFail("Unable to decode json")
            return
        }
        let persistentData = adClient.getAttributionData(details: data)
        XCTAssertEqual(persistentData?.adGroupId, "1234567890")
        XCTAssertEqual(persistentData?.adGroupName, "add-group")
        XCTAssertEqual(persistentData?.clickedWithin30D, "true")
        XCTAssertEqual(persistentData?.campaignId, "1234567890")
        XCTAssertEqual(persistentData?.campaignName, "Campaign Name")
        XCTAssertEqual(persistentData?.clickedDate, "2018-06-12T14:56:14Z")
        XCTAssertEqual(persistentData?.conversionDate, "2018-06-12T14:56:14Z")
        XCTAssertEqual(persistentData?.creativeSetId, "1234567890")
        XCTAssertEqual(persistentData?.creativeSetName, "Creative Name")
        XCTAssertEqual(persistentData?.adKeyword, "Keyword")
        XCTAssertEqual(persistentData?.orgName, "Org Name")
    }
    
    @available(iOS 14.3, *)
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

    @available(iOS 14.3, *)
    func testAdServiceErrorLocalizedDescription() {
        let error: Error = TealiumHTTPAdClient.AdServiceErrors.nilData
        XCTAssertEqual(error.localizedDescription, "AdServiceErrors.nilData")
    }
}
