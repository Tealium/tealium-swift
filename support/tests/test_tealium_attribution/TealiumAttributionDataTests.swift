//
//  AttributionModuleTests.swift
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
    AppleInternalKeys.attribution: AttributionKey.clickedWithin30D,
    AppleInternalKeys.orgName: AttributionKey.orgName,
    AppleInternalKeys.orgId: AttributionKey.orgId,
    AppleInternalKeys.campaignId: AttributionKey.campaignId,
    AppleInternalKeys.campaignName: AttributionKey.campaignName,
    AppleInternalKeys.clickDate: AttributionKey.clickedDate,
    AppleInternalKeys.purchaseDate: AttributionKey.purchaseDate,
    AppleInternalKeys.conversionDate: AttributionKey.conversionDate,
    AppleInternalKeys.conversionType: AttributionKey.conversionType,
    AppleInternalKeys.adGroupId: AttributionKey.adGroupId,
    AppleInternalKeys.adGroupName: AttributionKey.adGroupName,
    AppleInternalKeys.keyword: AttributionKey.adKeyword,
    AppleInternalKeys.keywordMatchType: AttributionKey.adKeywordMatchType,
    AppleInternalKeys.creativeSetId: AttributionKey.creativeSetId,
    AppleInternalKeys.creativeSetName: AttributionKey.creativeSetName,
    AppleInternalKeys.region: AttributionKey.region
]

class TealiumAttributionDataTests: XCTestCase {

    func testVolatileData() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let volatile = attributionData.volatileData
        XCTAssertEqual(volatile[AttributionKey.idfa] as! String, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
        XCTAssertEqual(volatile[AttributionKey.idfv] as! String, TealiumTestValue.testIDFVString, "IDFV values were unexpectedly different")
        XCTAssertEqual(volatile[AttributionKey.isTrackingAllowed] as! String, "true", "isTrackingAllowed values were unexpectedly different")
    }

    func testAllAttributionData() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: true, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let allData = attributionData.allAttributionData
        XCTAssertNotNil(allData[AttributionKey.clickedDate])
        XCTAssertNotNil(allData[AttributionKey.idfa])
        XCTAssertNotNil(allData[AttributionKey.idfv])
        XCTAssertNotNil(allData[AttributionKey.orgName])
        XCTAssertNotNil(allData[AttributionKey.campaignName])
        XCTAssertNotNil(allData[AttributionKey.creativeSetName])
    }

    func testSetPersistentAppDataWhenSearchAdsEnalbed() {
        let mockDisk = AttributionMockDiskStorage()
        let attributionData = AttributionData(diskStorage: mockDisk, isSearchAdsEnabled: true, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        attributionData.setPersistentAttributionData()
        XCTAssertEqual(mockDisk.retrieveCount, 2)
        XCTAssertNotNil(attributionData.persistentAttributionData)
    }

    func testSetPersistentAppDataWhenSearchAdNotEnalbed() {
        let mockDisk = AttributionMockDiskStorage()
        let attributionData = AttributionData(diskStorage: mockDisk, isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        attributionData.setPersistentAttributionData()
        XCTAssertEqual(mockDisk.retrieveCount, 1)
        XCTAssertNotNil(attributionData.persistentAttributionData)
    }

    func testIDFAAdTrackingEnabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
    }

    func testIDFAAdTrackingDisabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAStringAdTrackingDisabled, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingEnabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingDisabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIsLimitAdvertisingEnabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("true", isEnabled, "Limit Ad Trackingwas unexpectedly false")
    }

    func testIsLimitAdvertisingDisabled() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: false, identifierManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("false", isEnabled, "Limit Ad Trackingwas unexpectedly true")
    }

    func testSearchAds() {
        let attributionData = AttributionData(diskStorage: AttributionMockDiskStorage(), isSearchAdsEnabled: true, identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared, adClient: TestTealiumAdClient.shared)
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
