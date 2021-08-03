//
//  AttributionDataTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

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

    var defaultConfig: TealiumConfig!
    let mockDisk = AttributionMockDiskStorage()
    let mockAdAttribution = MockTealiumSKAdAttribution()

    override func setUpWithError() throws {
        defaultConfig = TestTealiumHelper().getConfig()
    }

    func createAttributionData(from config: TealiumConfig? = nil, idManager: TealiumASIdentifierManagerProtocol? = nil) -> AttributionData {
        AttributionData(config: config ?? defaultConfig, diskStorage: mockDisk, identifierManager: idManager ?? TealiumASIdentifierManagerAdTrackingEnabled.shared, adClient: TestTealiumAdClient.shared, adAttribution: mockAdAttribution)
    }

    func testVolatileData() {
        let attributionData = createAttributionData()
        let volatile = attributionData.volatileData
        XCTAssertEqual(volatile[AttributionKey.idfa] as! String, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
        XCTAssertEqual(volatile[AttributionKey.idfv] as! String, TealiumTestValue.testIDFVString, "IDFV values were unexpectedly different")
        XCTAssertEqual(volatile[AttributionKey.isTrackingAllowed] as! String, "true", "isTrackingAllowed values were unexpectedly different")

        XCTAssertEqual(volatile[AttributionKey.trackingAuthorization] as! String, "authorized", "trackingAuthorization values were unexpectedly different")
    }

    func testAllAttributionData() {
        defaultConfig.searchAdsEnabled = true
        let attributionData = createAttributionData(from: defaultConfig)
        let allData = attributionData.allAttributionData
        XCTAssertNotNil(allData[AttributionKey.clickedDate])
        XCTAssertNotNil(allData[AttributionKey.idfa])
        XCTAssertNotNil(allData[AttributionKey.idfv])
        XCTAssertNotNil(allData[AttributionKey.orgName])
        XCTAssertNotNil(allData[AttributionKey.trackingAuthorization])
        XCTAssertNotNil(allData[AttributionKey.campaignName])
        XCTAssertNotNil(allData[AttributionKey.creativeSetName])
    }

    func testSetPersistentAppDataWhenSearchAdsEnalbed() {
        defaultConfig.searchAdsEnabled = true
        let attributionData = createAttributionData(from: defaultConfig)
        attributionData.setPersistentAttributionData()
        XCTAssertEqual(mockDisk.retrieveCount, 2)
        XCTAssertNotNil(attributionData.persistentAttributionData)
    }

    func testSetPersistentAppDataWhenSearchAdNotEnalbed() {
        let attributionData = createAttributionData(from: defaultConfig)
        attributionData.setPersistentAttributionData()
        XCTAssertEqual(mockDisk.retrieveCount, 1)
        XCTAssertNotNil(attributionData.persistentAttributionData)
    }

    func testIDFAAdTrackingEnabled() {
        let attributionData = createAttributionData()
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
    }
    
    func testIDFAAdTrackingReset() {
        let identifierManager = TealiumASIdentifierManagerAdTrackingEnabled()
        let attributionData = createAttributionData(from: defaultConfig, idManager: identifierManager)
        XCTAssertEqual(attributionData.allAttributionData[AttributionKey.idfa] as! String, TealiumTestValue.testIDFAString, "IDFA values were unexpectedly different")
        identifierManager.advertisingIdentifier = TealiumTestValue.testIDFAResetString
        XCTAssertEqual(attributionData.allAttributionData[AttributionKey.idfa] as! String, TealiumTestValue.testIDFAResetString, "IDFA values were unexpectedly different")
    }

    func testIDFAAdTrackingDisabled() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfa = attributionData.idfa
        XCTAssertEqual(idfa, TealiumTestValue.testIDFAStringAdTrackingDisabled, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingEnabled() {
        let attributionData = createAttributionData(from: defaultConfig)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIDFVAdTrackingDisabled() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let idfv = attributionData.idfv
        XCTAssertEqual(idfv, TealiumTestValue.testIDFVString, "IDFA values were unexpectedly different")
    }

    func testIsLimitAdvertisingEnabled() {
        let attributionData = createAttributionData()
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("true", isEnabled, "Limit Ad Trackingwas unexpectedly false")
    }

    func testIsLimitAdvertisingDisabled() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        let isEnabled = attributionData.isAdvertisingTrackingEnabled
        XCTAssertEqual("false", isEnabled, "Limit Ad Trackingwas unexpectedly true")
    }

    func testSearchAds() {
        defaultConfig.searchAdsEnabled = true
        let attributionData = createAttributionData(from: defaultConfig)
        let expectation = self.expectation(description: "search_ads")
        let waiter = XCTWaiter()
        attributionData.appleSearchAdsData { _ in
            guard let appleAttributionDetails = attributionData.persistentAttributionData else {
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

    @available(iOS 14, *)
    func testTrackingAuthorizationStatus_returnsCorrectString() {
        let options: [UInt] = [UInt(0), UInt(1), UInt(2), UInt(3)]
        let expected: [String] = [TrackingAuthorizationDescription.notDetermined, TrackingAuthorizationDescription.restricted, TrackingAuthorizationDescription.denied, TrackingAuthorizationDescription.authorized]
        options.enumerated().forEach {
            let actual = ATTrackingManager.AuthorizationStatus.string(from: $0.element)
            XCTAssertEqual(actual, expected[$0.offset])
        }
    }

    @available(iOS 14, *)
    func testTrackingAuthorized() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingEnabled.shared)
        attributionData.identifierManager.attManager = MockATTrackingManagerTrackingAuthorized()
        let trackingAuthStatus = attributionData.trackingAuthorizationStatus
        XCTAssertEqual("authorized", trackingAuthStatus, "Tracking Authorization Status was an unexpected value")
    }

    @available(iOS 14, *)
    func testTrackingDenied() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        attributionData.identifierManager.attManager = MockATTrackingManagerTrackingDenied()
        let trackingAuthStatus = attributionData.trackingAuthorizationStatus
        XCTAssertEqual("denied", trackingAuthStatus, "Tracking Authorization Status was an unexpected value")
    }

    @available(iOS 14, *)
    func testTrackingNotDetermined() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        attributionData.identifierManager.attManager = MockATTrackingManagerTrackingNotDetermined()
        let trackingAuthStatus = attributionData.trackingAuthorizationStatus
        XCTAssertEqual("notDetermined", trackingAuthStatus, "Tracking Authorization Status was an unexpected value")
    }

    @available(iOS 14, *)
    func testTrackingRestricted() {
        let attributionData = createAttributionData(from: defaultConfig, idManager: TealiumASIdentifierManagerAdTrackingDisabled.shared)
        attributionData.identifierManager.attManager = MockATTrackingManagerTrackingRestricted()
        let trackingAuthStatus = attributionData.trackingAuthorizationStatus
        XCTAssertEqual("restricted", trackingAuthStatus, "Tracking Authorization Status was an unexpected value")
    }
    
    @available(iOS 14, *)
    func testTrackingAuthorizationStatusChanged() {
        let identifierManager = TealiumASIdentifierManagerAdTrackingChangable(enabled: false)
        let attributionData = createAttributionData(from: defaultConfig, idManager: identifierManager)
        XCTAssertEqual("denied", attributionData.allAttributionData[AttributionKey.trackingAuthorization] as! String, "Tracking Authorization Status was an unexpected value")
        identifierManager.select(enabled: true)
        XCTAssertEqual("authorized", attributionData.allAttributionData[AttributionKey.trackingAuthorization] as! String, "Tracking Authorization Status was an unexpected value")
    }

}

public class TealiumASIdentifierManagerAdTrackingEnabled: TealiumASIdentifierManagerProtocol {

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManagerAdTrackingEnabled()

    public var attManager: TealiumATTrackingManagerProtocol = MockATTrackingManagerTrackingAuthorized()

    init() {

    }

    public lazy var advertisingIdentifier: String = {
        return TealiumTestValue.testIDFAString
    }()

    public lazy var isAdvertisingTrackingEnabled: String = {
        return "true"
    }()

    public var trackingAuthorizationStatus: String {
        return attManager.trackingAuthorizationStatusDescription
    }

    public lazy var identifierForVendor: String = {
        return TealiumTestValue.testIDFVString
    }()
}

public class TealiumASIdentifierManagerAdTrackingDisabled: TealiumASIdentifierManagerProtocol {

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManagerAdTrackingDisabled()

    public var attManager: TealiumATTrackingManagerProtocol = MockATTrackingManagerTrackingDenied()

    init() {

    }

    public lazy var advertisingIdentifier: String = {
        return TealiumTestValue.testIDFAStringAdTrackingDisabled
    }()

    public lazy var isAdvertisingTrackingEnabled: String = {
        return "false"
    }()

    public var trackingAuthorizationStatus: String {
        return attManager.trackingAuthorizationStatusDescription
    }

    public lazy var identifierForVendor: String = {
        return TealiumTestValue.testIDFVString
    }()
}

fileprivate func identifierManager(forEnabledState enabled: Bool) -> TealiumASIdentifierManagerProtocol {
    if (enabled) {
        return TealiumASIdentifierManagerAdTrackingEnabled.shared
    } else {
        return TealiumASIdentifierManagerAdTrackingDisabled.shared
    }
}

public class TealiumASIdentifierManagerAdTrackingChangable: TealiumASIdentifierManagerProtocol {
    public var attManager: TealiumATTrackingManagerProtocol {
        get {
            self.selected.attManager
        }
        set {
            
        }
    }
    
    public static let shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManagerAdTrackingChangable(enabled: false)
    
    private var selected: TealiumASIdentifierManagerProtocol
    
    func select(enabled: Bool) {
        self.selected = identifierManager(forEnabledState: enabled)
    }

    init(enabled: Bool) {
        self.selected = identifierManager(forEnabledState: enabled)
    }

    public var advertisingIdentifier: String {
        self.selected.advertisingIdentifier
    }

    public var isAdvertisingTrackingEnabled: String {
        self.selected.isAdvertisingTrackingEnabled
    }

    public var trackingAuthorizationStatus: String {
        self.selected.trackingAuthorizationStatus
    }

    public var identifierForVendor: String {
        self.selected.identifierForVendor
    }
}

public class MockATTrackingManagerTrackingAuthorized: TealiumATTrackingManagerProtocol {
    public static var trackingAuthorizationStatus: UInt = 3
    public var trackingAuthorizationStatusDescription = TrackingAuthorizationDescription.authorized
}

public class MockATTrackingManagerTrackingDenied: TealiumATTrackingManagerProtocol {
    public static var trackingAuthorizationStatus: UInt = 2
    public var trackingAuthorizationStatusDescription =
        TrackingAuthorizationDescription.denied
}

public class MockATTrackingManagerTrackingNotDetermined: TealiumATTrackingManagerProtocol {
    public static var trackingAuthorizationStatus: UInt = 0
    public var trackingAuthorizationStatusDescription = TrackingAuthorizationDescription.notDetermined
}

public class MockATTrackingManagerTrackingRestricted: TealiumATTrackingManagerProtocol {
    public static var trackingAuthorizationStatus: UInt = 1
    public var trackingAuthorizationStatusDescription = TrackingAuthorizationDescription.restricted
}

public class TestTealiumAdClient: TealiumAdClientProtocol {

    public static var shared: TealiumAdClientProtocol = TestTealiumAdClient()

    private init() {

    }

    public func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        completionHandler(mockAppleAttributionData, nil)
    }
}
