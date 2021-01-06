//
//  ConsentManagerModuleTests.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class ConsentManagerModuleTests: XCTestCase {

    var config: TealiumConfig!
    var track: TealiumTrackRequest!
    
    var module: ConsentManagerModule {
        let context = TestTealiumHelper.context(with: TestTealiumHelper().getConfig(), dataLayer: MockDataLayerManager())
        return ConsentManagerModule(context: context, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
    }
    
    func createModule(with config: TealiumConfig? = nil, dataLayer: DataLayerManagerProtocol? = nil) -> ConsentManagerModule {
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig(), dataLayer: dataLayer ?? MockDataLayerManager())
        return ConsentManagerModule(context: context, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
    }

    override func setUp() {
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        config.appDelegateProxyEnabled = false
        config.consentPolicy = .gdpr
    }

    func testConsentManagerIsDisabledAutomatically() {
        let config2 = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        let teal = Tealium(config: config2)
        XCTAssertNil(teal.consentManager)
    }

    func testUpdateConfig() {
        var newConfig = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        newConfig.consentPolicy = nil
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        let module = createModule(with: config)
        module.updateConfig(updateRequest)
        XCTAssertNil(module.consentManager)
        let expect = expectation(description: "consent mgr init")
        newConfig = TealiumConfig(account: "testAccount2", profile: "testProfile2", environment: "testEnvironment")
        newConfig.consentPolicy = .gdpr
        updateRequest = TealiumUpdateConfigRequest(config: newConfig)
        module.updateConfig(updateRequest)
        expect.fulfill()
        XCTAssertNotNil(module.consentManager)
        wait(for: [expect], timeout: 2.0)
    }

    func testShouldQueueIsBatchTrackRequest() {
        track = TealiumTrackRequest(data: ["test": "track"])
        let batchTrack = TealiumBatchTrackRequest(trackRequests: [track, track, track])
        let queue = module.shouldQueue(request: batchTrack)
        XCTAssertTrue(queue.0)
        XCTAssertTrue(queue.1?["queue_reason"] as? String == "batching_enabled", "Consent Manager Module: \(#function) - Track call contained unexpected value")
    }

    func testShouldQueueAllowAuditingEvents() {
        let auditingEvents = [
            ConsentKey.consentPartialEventName,
            ConsentKey.consentGrantedEventName,
            ConsentKey.consentDeclinedEventName,
            ConsentKey.gdprConsentCookieEventName
        ]
        auditingEvents.forEach {
            track = TealiumTrackRequest(data: [TealiumKey.event: $0])
            let queue = module.shouldQueue(request: track)
            XCTAssertFalse(queue.0)
            XCTAssertNil(queue.1)
        }
    }

    func testShouldQueueTrackingStatusTrackingQueued() {
        module.consentManager?.resetUserConsentPreferences()
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertTrue(queue.0)
        XCTAssertTrue(queue.1?["queue_reason"] as? String == "consentmanager", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        XCTAssertTrue(queue.1?["tracking_consented"] as? String == TealiumValue.unknown, "Consent Manager Module: \(#function) - Track call contained unexpected value")
    }

    func testShouldQueueTrackingStatusTrackingAllowed() {
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.userConsentCategories = [.affiliates, .analytics, .bigData]
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
        XCTAssertTrue(queue.1?["tracking_consented"] as? String == "consented", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        guard let categories = queue.1?["consent_categories"] as? [String] else {
            XCTFail("Consent categories should be present in dictionary")
            return
        }
        XCTAssertEqual(categories.count, 3)
    }

    func testShouldQueueTrackingStatusTrackingForbidden() {
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
        XCTAssertTrue(queue.1?["tracking_consented"] as? String == "notConsented", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        guard let categories = queue.1?["consent_categories"] as? [String] else {
            XCTFail("Consent categories should be present in dictionary")
            return
        }
        XCTAssertEqual(categories.count, 0)
    }

    func testShouldDropWhenTrackingForbidden() {
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        track = TealiumTrackRequest(data: ["test": "track"])
        let drop = module.shouldDrop(request: track)
        XCTAssertTrue(drop)
    }

    func testShouldNotDropWhenTrackingAllowed() {
        module.consentManager?.userConsentStatus = .consented
        track = TealiumTrackRequest(data: ["test": "track"])
        let drop = module.shouldDrop(request: track)
        XCTAssertFalse(drop)
    }

    func testShouldPurgeWhenTrackingForbidden() {
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        track = TealiumTrackRequest(data: ["test": "track"])
        let purge = module.shouldPurge(request: track)
        XCTAssertTrue(purge)
    }

    func testShouldNotPurgeWhenTrackingAllowed() {
        module.consentManager?.userConsentStatus = .consented
        track = TealiumTrackRequest(data: ["test": "track"])
        let purge = module.shouldPurge(request: track)
        XCTAssertFalse(purge)
    }

    func testAddConsentDataToTrackWhenConsented() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        let expected: [String: Any] = [
            ConsentKey.trackingConsentedKey: "consented",
            ConsentKey.consentCategoriesKey: ["analytics",
                                              "affiliates",
                                              "display_ads",
                                              "email",
                                              "personalization",
                                              "search",
                                              "social",
                                              "big_data",
                                              "mobile",
                                              "engagement",
                                              "monitoring",
                                              "crm",
                                              "cdp",
                                              "cookiematch",
                                              "misc"],
            "test": "track",
            "policy": "gdpr"
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = module.addConsentDataToTrack(track).trackDictionary
        XCTAssertNotNil(trackWithConsentData[TealiumKey.requestUUID])
        trackWithConsentData[TealiumKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }

    func testAddConsentDataToTrackWhenNotConsented() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        let expected: [String: Any] = [
            ConsentKey.trackingConsentedKey: "notConsented",
            ConsentKey.consentCategoriesKey: [],
            "test": "track",
            "policy": "gdpr"
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = module.addConsentDataToTrack(track).trackDictionary
        XCTAssertNotNil(trackWithConsentData[TealiumKey.requestUUID])
        trackWithConsentData[TealiumKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }

    func testAddConsentDataToTrackWhenResetConsentStatus() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.resetUserConsentPreferences()
        let expected: [String: Any] = [
            ConsentKey.trackingConsentedKey: TealiumValue.unknown,
            ConsentKey.consentCategoriesKey: [],
            "test": "track",
            "policy": "gdpr"
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = module.addConsentDataToTrack(track).trackDictionary
        XCTAssertNotNil(trackWithConsentData[TealiumKey.requestUUID])
        trackWithConsentData[TealiumKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }
    
    func testAddConsentDataToTrackWhenMigratedFromLegacyStorage() {
        let module = createModule(dataLayer: MockMigratedDataLayer())
        let expected: [String: Any] = [
            ConsentKey.trackingConsentedKey: "consented",
            ConsentKey.consentCategoriesKey: [TealiumConsentCategories.affiliates.rawValue,
                                              TealiumConsentCategories.bigData.rawValue,
                                              TealiumConsentCategories.crm.rawValue,
                                              TealiumConsentCategories.engagement.rawValue],
            "test": "track",
            "policy": "gdpr"
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = module.addConsentDataToTrack(track).trackDictionary
        XCTAssertNotNil(trackWithConsentData[TealiumKey.requestUUID])
        trackWithConsentData[TealiumKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }
    
    func testAddConsentDataToTrackNoLegacyStorage() {
        config.consentPolicy = .ccpa
        let module = createModule(with: config, dataLayer: MockMigratedDataLayerNoData())
        let expected: [String: Any] = [
            "test": "track",
            "policy": "ccpa",
            "do_not_sell": false
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = module.addConsentDataToTrack(track).trackDictionary
        XCTAssertNotNil(trackWithConsentData[TealiumKey.requestUUID])
        trackWithConsentData[TealiumKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }
    
    func testExpireConsentReturnsIfLastSetNil() {
        let context = TestTealiumHelper.context(with: config)
        let module = ConsentManagerModule(context: context,
                                          delegate: nil,
                                          diskStorage: ConsentMockDiskStorage()) { _ in }
        let consentManager = ConsentManager(config: config, delegate: nil, diskStorage: ConsentMockDiskStorage(), dataLayer: nil)
        module.consentManager = consentManager
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.lastConsentUpdate = nil
        module.expireConsent()
        XCTAssertEqual(module.consentManager?.userConsentStatus, .consented)
    }
    
    func testExpireConsentReturnsIfDateIsLessThanLastSet() {
        config.consentExpiry = (24, .hours)
        let context = TestTealiumHelper.context(with: config)
        let module = ConsentManagerModule(context: context,
                                          delegate: nil,
                                          diskStorage: ConsentMockDiskStorage()) { _ in }
        module.consentManager?.userConsentCategories = [.analytics, .affiliates]
        module.consentManager?.lastConsentUpdate = TimeTraveler().travel(by: 60 * 60 * 24 + 1)
        module.expireConsent()
        XCTAssertEqual(module.consentManager?.userConsentCategories, [.analytics, .affiliates])
    }
    
    func testExpireConsentSetsCategoriesToNil() {
        config.consentExpiry = (24, .hours)
        let context = TestTealiumHelper.context(with: config)
        let module = ConsentManagerModule(context: context,
                                          delegate: nil,
                                          diskStorage: ConsentMockDiskStorage()) { _ in }
        let consentManager = ConsentManager(config: config, delegate: nil, diskStorage: ConsentMockDiskStorage(), dataLayer: nil)
        module.consentManager = consentManager
        module.consentManager?.userConsentCategories = TealiumConsentCategories.all
        module.consentManager?.lastConsentUpdate = TimeTraveler().travel(by: -(60 * 60 * 24 + 1))
        module.expireConsent()
        XCTAssertEqual(module.consentManager?.userConsentCategories?.count, 0)
        XCTAssertEqual(module.consentManager?.consentPreferencesStorage?.preferences?.consentStatus, .unknown)
    }

}

extension ConsentManagerModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }
    func requestDequeue(reason: String) { }
    func requestTrack(_ track: TealiumTrackRequest) { }
}
