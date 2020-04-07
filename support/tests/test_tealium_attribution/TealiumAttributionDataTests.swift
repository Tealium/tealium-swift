//
//  TealiumAttributionModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

//  Application Test do to UIKit not being available to Unit Test Bundle

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

let attributionValues = Dictionary(uniqueKeysWithValues: AppleInternalKeys.allCases.map { ($0, "mockdata" as NSObject) }) as NSObject
private let mockAppleAttributionData: [String: NSObject] = ["Version3.1": attributionValues]

let keyTranslation = [
    AppleInternalKeys.attribution: TealiumAttributionKey.clickedWithin30D,
    AppleInternalKeys.orgName: TealiumAttributionKey.orgName,
    AppleInternalKeys.orgId: TealiumAttributionKey.orgId,
    AppleInternalKeys.campaignId: TealiumAttributionKey.campaignId,
    AppleInternalKeys.campaignName: TealiumAttributionKey.campaignName,
    AppleInternalKeys.clickDate: TealiumAttributionKey.clickedDate,
    AppleInternalKeys.purchaseDate: TealiumAttributionKey.purchaseDate,
    AppleInternalKeys.conversionDate: TealiumAttributionKey.conversionDate,
    AppleInternalKeys.conversionType: TealiumAttributionKey.conversionType,
    AppleInternalKeys.adGroupId: TealiumAttributionKey.adGroupId,
    AppleInternalKeys.adGroupName: TealiumAttributionKey.adGroupName,
    AppleInternalKeys.keyword: TealiumAttributionKey.adKeyword,
    AppleInternalKeys.keywordMatchType: TealiumAttributionKey.adKeywordMatchType,
    AppleInternalKeys.creativeSetId: TealiumAttributionKey.creativeSetId,
    AppleInternalKeys.creativeSetName: TealiumAttributionKey.creativeSetName,
    AppleInternalKeys.region: TealiumAttributionKey.region
]

class TealiumAttributionDataTests: XCTestCase {

    func testIDFAAdTrackingEnabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
    }

    func testIDFAAdTrackingDisabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAStringAdTrackingDisabled, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingEnabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingDisabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIsLimitAdvertisingEnabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("true", isEnabled, "Limit Ad Trackingwas unexpectedly false")
    }

    func testIsLimitAdvertisingDisabled() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("false", isEnabled, "Limit Ad Trackingwas unexpectedly true")
    }

    func testSearchAds() {
        let attributionData = TealiumAttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: true, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared, adClient: TestTealiumAdClient.shared)
        let expectation = self.expectation(description: "search_ads")
        let waiter = XCTWaiter()
        attributionData.appleSearchAdsData { _ in
            guard let appleAttributionDetails = attributionData.appleAttributionDetails else {
                XCTFail("Attribution returned a nil dictionary")
                return
            }
            guard let attributionValues = attributionValues as? [String: Any] else {
                XCTFail("Attribution values could not be cast to [String: Any]")
                return
            }

            XCTAssertEqual(attributionValues.count, appleAttributionDetails.count, "Keys missing in returned attribution data")

            attributionValues.forEach { key, mockValue in
                guard let tealiumKey = keyTranslation[key],
                    let mockValue = mockValue as? String,
                    let tealiumValue = appleAttributionDetails[tealiumKey] else {
                        XCTFail("Key could not be found")
                        return
                }
                XCTAssertEqual(tealiumValue, mockValue)
            }

            expectation.fulfill()
        }
        waiter.wait(for: [expectation], timeout: 5.0)
    }

}

public class TealiumASIdentifierManagerAdTrackingEnabled: TealiumASIdentifierManagerProtocol {

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManagerAdTrackingEnabled()

    private init() {

    }

    public lazy var advertisingIdentifier: String = {
        return TealiumTestValue.testIDFAString
    }()

    public lazy var isAdvertisingTrackingEnabled: String = {
        return "true"
    }()

    public lazy var identifierForVendor: String = {
        return TealiumTestValue.testIDFVString
    }()
}

public class TealiumASIdentifierManagerAdTrackingDisabled: TealiumASIdentifierManagerProtocol {

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManagerAdTrackingDisabled()

    private init() {

    }

    public lazy var advertisingIdentifier: String = {
        return TealiumTestValue.testIDFAStringAdTrackingDisabled
    }()

    public lazy var isAdvertisingTrackingEnabled: String = {
        return "false"
    }()

    public lazy var identifierForVendor: String = {
        return TealiumTestValue.testIDFVString
    }()
}

public class TestTealiumAdClient: TealiumAdClientProtocol {

    public static var shared: TealiumAdClientProtocol = TestTealiumAdClient()

    private init() {

    }

    public func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        completionHandler(mockAppleAttributionData, nil)
    }
}
