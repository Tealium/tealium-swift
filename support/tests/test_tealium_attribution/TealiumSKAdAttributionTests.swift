//
//  TealiumSKAdAttributionTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

class TealiumSKAdAttributionTests: XCTestCase {

    let attributor = MockAttributor()
    let mockAdAttribution = MockTealiumSKAdAttribution()
    let mockAttributionData = MockAttributionData()
    var defaultConfig = TestTealiumHelper().getConfig()

    func createModule(from config: TealiumConfig? = nil, attributionData: AttributionDataProtocol? = nil) -> AttributionModule {
        let tealium = Tealium(config: config ?? defaultConfig)
        let context = TealiumContext(config: config ?? defaultConfig, dataLayer: DummyDataManager(), tealium: tealium)
        return AttributionModule(context: context, delegate: nil, diskStorage: AttributionMockDiskStorage()) { _ in }
    }

    func createAttributionData(from config: TealiumConfig? = nil, adAttribution: TealiumSKAdAttributionProtocol? = nil) -> AttributionDataProtocol {
        return AttributionData(config: config ?? defaultConfig, diskStorage: AttributionMockDiskStorage(), identifierManager: TealiumASIdentifierManagerAdTrackingEnabled.shared, adClient: TestTealiumAdClient.shared, adAttribution: adAttribution ?? mockAdAttribution)
    }

    // MARK: Attributor tests
    func testMethodRunUponInit_registerAppForAdNetworkAttribution_skAdNetworkEnabled() {
        defaultConfig.skAdAttributionEnabled = true
        MockAttributor.registerAdNetworkCount = 0
        _ = createAttributionData(from: defaultConfig, adAttribution: TealiumSKAdAttribution(config: defaultConfig, attributor: attributor))
        XCTAssertEqual(MockAttributor.registerAdNetworkCount, 1)
    }

    func testMethodNotRunUponInit_registerAppForAdNetworkAttribution_skAdNetworkDisabled() {
        MockAttributor.registerAdNetworkCount = 0
        defaultConfig.skAdAttributionEnabled = false
        _ = createAttributionData(from: defaultConfig, adAttribution: TealiumSKAdAttribution(config: defaultConfig, attributor: attributor))
        XCTAssertEqual(MockAttributor.registerAdNetworkCount, 0)
    }

    // MARK: Attribution Module tests
    func testExtractConversionInfoRun_onWillTrack_skAdNetworkEnabled() {
        defaultConfig.skAdAttributionEnabled = true
        let attributionData = createAttributionData(from: defaultConfig)
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track = TealiumTrackRequest(data: ["hello": "world"])
        module.willTrack(request: track)
        XCTAssertEqual(mockAdAttribution.extractConversionInfoCount, 1)
    }

    func testExtractConversionInfoNotRun_onWillTrack_skAdNetworkDisabled() {
        defaultConfig.skAdAttributionEnabled = false
        let attributionData = createAttributionData(from: defaultConfig)
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track = TealiumTrackRequest(data: ["hello": "world"])
        module.willTrack(request: track)
        XCTAssertEqual(mockAdAttribution.extractConversionInfoCount, 0)
    }

    func testExtractConversionInfoRun_onWillTrack_batchTrack() {
        defaultConfig.skAdAttributionEnabled = true
        let attributionData = createAttributionData(from: defaultConfig)
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track1 = TealiumTrackRequest(data: ["hello1": "world1"])
        let track2 = TealiumTrackRequest(data: ["hello2": "world2"])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track1, track2])
        module.willTrack(request: batchTrack)
        XCTAssertEqual(mockAdAttribution.extractConversionInfoCount, 2)
    }

    func testUpdateConversionValueRun_onWillTrack_skAdNetworkEnabled() {
        defaultConfig.skAdAttributionEnabled = true
        let attributionData = MockAttributionData()
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track = TealiumTrackRequest(data: ["hello": "world"])
        module.willTrack(request: track)
        XCTAssertEqual(attributionData.updateConversionValueCalled, 1)
    }

    func testUpdateConversionValueRun_onWillTrack_skAdNetworkDisabled() {
        defaultConfig.skAdAttributionEnabled = false
        let attributionData = MockAttributionData()
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track = TealiumTrackRequest(data: ["hello": "world"])
        module.willTrack(request: track)
        XCTAssertEqual(attributionData.updateConversionValueCalled, 0)
    }

    func testUpdateConversionValueRun_onWillTrack_batchTrack() {
        defaultConfig.skAdAttributionEnabled = true
        let attributionData = MockAttributionData()
        let module = createModule(from: defaultConfig)
        module.attributionData = attributionData
        let track1 = TealiumTrackRequest(data: ["hello1": "world1"])
        let track2 = TealiumTrackRequest(data: ["hello2": "world2"])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track1, track2])
        module.willTrack(request: batchTrack)
        XCTAssertEqual(attributionData.updateConversionValueCalled, 1)
    }

    // MARK: Attirbution Data tests
    func testMethodRun_updateConversionValue_fromExtractConversionInfo() {
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = ["test_event": "test_key"]
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "test_event", "test_key": 10])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(MockAttributor.updateConversionCount, 1)
    }

    func testMethodNotRun_updateConversionValue_skAdConversionKeysUndefined() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = nil
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "test_event", "test_key": 10])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testMethodNotRun_updateConversionValue_NoEvent() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = ["test_event": "test_key"]
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["hello": "world"])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testMethodNotRun_updateConversionValue_EventNoValue() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = nil
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "test_event"])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testMethodNotRun_updateConversionValue_ValueNotInt() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = ["test_event": "test_key"]
        let mockLogger = MockLogger(config: defaultConfig)
        defaultConfig.logger = mockLogger
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "test_event", "test_key": "hello"])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(mockLogger.logCount, 1)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testMethodNotRun_updateConversionValue_ValueGreaterThanMax() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = ["test_event": "test_key"]
        let mockLogger = MockLogger(config: defaultConfig)
        defaultConfig.logger = mockLogger
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "test_event", "test_key": 100])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(mockLogger.logCount, 1)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testMethodNotRun_updateConversionValue_KeyNotFoundInTrack() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdAttributionEnabled = true
        defaultConfig.skAdConversionKeys = ["tester": "test"]
        let mockLogger = MockLogger(config: defaultConfig)
        defaultConfig.logger = mockLogger
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["tealium_event": "tester"])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(mockLogger.logCount, 1)
        XCTAssertEqual(MockAttributor.updateConversionCount, 0)
    }

    func testExtractConversionInfo_registerAdNetworkNotRun_skAdNetworkDisabled() {
        MockAttributor.updateConversionCount = 0
        defaultConfig.skAdConversionKeys = ["tester": "test"]
        let adAttribution = TealiumSKAdAttribution(config: defaultConfig, attributor: attributor)
        let track = TealiumTrackRequest(data: ["hello": "world"])
        adAttribution.extractConversionInfo(from: track)
        XCTAssertEqual(MockAttributor.registerAdNetworkCount, 0)
    }

}

class MockTealiumSKAdAttribution: TealiumSKAdAttributionProtocol {

    var updateConversionCount = 0
    var extractConversionInfoCount = 0
    var registerAdNetworkCount = 0

    func updateConversion(value: Int) {
        updateConversionCount += 1
    }

    func extractConversionInfo(from dispatch: TealiumTrackRequest) {
        extractConversionInfoCount += 1
    }

    func registerAdNetwork() {
        registerAdNetworkCount += 1
    }
}

class MockAttributor: Attributable {

    static var registerAdNetworkCount = 0
    static var updateConversionCount = 0

    @available(iOS 11.3, *)
    static func registerAppForAdNetworkAttribution() {
        registerAdNetworkCount += 1
    }

    @available(iOS 14.0, *)
    static func updateConversionValue(_ conversionValue: Int) {
        updateConversionCount += 1
    }
}

class MockLogger: TealiumLoggerProtocol {

    var logCount = 0

    var config: TealiumConfig?

    required init(config: TealiumConfig) {
        self.config = config
    }

    func log(_ request: TealiumLogRequest) {
        logCount += 1
    }

}
