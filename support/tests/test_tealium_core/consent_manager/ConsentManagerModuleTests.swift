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
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig(), dataLayer: MockDataLayerManager())
        return ConsentManagerModule(context: context, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
    }
    
    func createModule(with config: TealiumConfig? = nil, dataLayer: DataLayerManagerProtocol? = nil) -> ConsentManagerModule {
        let context = TestTealiumHelper.context(with: config ?? TestTealiumHelper().getConfig(), dataLayer: dataLayer ?? MockDataLayerManager())
        return ConsentManagerModule(context: context, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
    }

    override func setUp() {
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        config.consentPolicy = .gdpr
    }

    func testConsentManagerIsDisabledAutomatically() {
        let config2 = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        let teal = Tealium(config: config2)
        XCTAssertNil(teal.consentManager)
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
            ConsentKey.gdprConsentCookieEventName,
            ConsentKey.ccpaCookieEventName
        ]
        auditingEvents.forEach {
            track = TealiumTrackRequest(data: [TealiumDataKey.event: $0])
            let queue = module.shouldQueue(request: track)
            XCTAssertFalse(queue.0)
            XCTAssertNotNil(queue.1)
        }
    }
    
    func testShouldQueueAddsConsentStatusAndCategory() {
        let auditingEvents = [
            ConsentKey.consentPartialEventName,
            ConsentKey.consentGrantedEventName,
            ConsentKey.consentDeclinedEventName,
            ConsentKey.gdprConsentCookieEventName,
            ConsentKey.ccpaCookieEventName,
            "someEvent",
            "someOtherEvent"
        ]
        auditingEvents.forEach {
            track = TealiumTrackRequest(data: [TealiumDataKey.event: $0])
            let queue = module.shouldQueue(request: track)
            XCTAssertNotNil(queue.1?[TealiumDataKey.consentStatus])
            XCTAssertNotNil(queue.1?[TealiumDataKey.consentCategoriesKey])
        }
    }

    func testShouldQueueTrackingStatusTrackingQueued() {
        module.consentManager?.resetUserConsentPreferences()
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertTrue(queue.0)
        XCTAssertTrue(queue.1?["queue_reason"] as? String == "consentmanager", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        XCTAssertTrue(queue.1?["consent_status"] as? String == TealiumValue.unknown, "Consent Manager Module: \(#function) - Track call contained unexpected value")
    }

    func testShouldQueueTrackingStatusTrackingAllowed() {
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.userConsentCategories = [.affiliates, .analytics, .bigData]
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
        XCTAssertTrue(queue.1?["consent_status"] as? String == "consented", "Consent Manager Module: \(#function) - Track call contained unexpected value")
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
        XCTAssertTrue(queue.1?["consent_status"] as? String == "notConsented", "Consent Manager Module: \(#function) - Track call contained unexpected value")
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
    
    func testShouldNotQueueWhenIsAuditEvent() {
        let auditEvents = [ConsentKey.consentPartialEventName,
                           ConsentKey.consentGrantedEventName,
                           ConsentKey.consentDeclinedEventName,
                           ConsentKey.gdprConsentCookieEventName,
                           ConsentKey.ccpaCookieEventName]
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        auditEvents.forEach {
            track = TealiumTrackRequest(data: ["tealium_event": $0])
            let queue = module.shouldQueue(request: track)
            XCTAssertFalse(queue.0)
        }
    }
    
    func testShouldNotDropWhenIsAuditEvent() {
        let auditEvents = [ConsentKey.consentPartialEventName,
                           ConsentKey.consentGrantedEventName,
                           ConsentKey.consentDeclinedEventName,
                           ConsentKey.gdprConsentCookieEventName,
                           ConsentKey.ccpaCookieEventName]
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        auditEvents.forEach {
            track = TealiumTrackRequest(data: ["tealium_event": $0])
            let drop = module.shouldDrop(request: track)
            XCTAssertFalse(drop)
        }
    }
    
    func testShouldNotPurgeWhenIsAuditEvent() {
        let auditEvents = [ConsentKey.consentPartialEventName,
                           ConsentKey.consentGrantedEventName,
                           ConsentKey.consentDeclinedEventName,
                           ConsentKey.gdprConsentCookieEventName,
                           ConsentKey.ccpaCookieEventName]
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        auditEvents.forEach {
            track = TealiumTrackRequest(data: ["tealium_event": $0])
            let purge = module.shouldPurge(request: track)
            XCTAssertFalse(purge)
        }
    }

    func testShouldNotPurgeWhenTrackingAllowed() {
        module.consentManager?.userConsentStatus = .consented
        track = TealiumTrackRequest(data: ["test": "track"])
        let purge = module.shouldPurge(request: track)
        XCTAssertFalse(purge)
    }
    
    func testOverrideConsentCategoriesKey() {
        config.consentPolicy = .gdpr
        let overrideKey = "test_override_consent_categories_key"
        config.overrideConsentCategoriesKey = overrideKey
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.userConsentCategories = [.affiliates, .analytics, .email, .personalization, .mobile]
        let lastUpdate = module.consentManager?.lastConsentUpdate?.unixTimeMilliseconds
        let expected: [String:Any] = [
            TealiumDataKey.consentStatus: "consented",
            overrideKey : ["affiliates", "analytics", "email", "personalization", "mobile"],
            TealiumDataKey.policyKey: "gdpr",
            TealiumDataKey.consentLastUpdated:
                lastUpdate!
        ]
        let consentData = module.getConsentData()
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: consentData))
    }

    func testAddConsentDataToTrackWhenConsented() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        let lastUpdate = module.consentManager?.lastConsentUpdate?.unixTimeMilliseconds
        let expected: [String: Any] = [
            TealiumDataKey.consentStatus: "consented",
            TealiumDataKey.consentCategoriesKey: ["analytics",
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
            TealiumDataKey.policyKey: "gdpr",
            TealiumDataKey.consentLastUpdated: lastUpdate!
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = track.trackDictionary
        trackWithConsentData += module.getConsentData()
        XCTAssertNotNil(trackWithConsentData[TealiumDataKey.requestUUID])
        trackWithConsentData[TealiumDataKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }

    func testAddConsentDataToTrackWhenNotConsented() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .notConsented
        let lastUpdate = module.consentManager?.lastConsentUpdate?.unixTimeMilliseconds
        let expected: [String: Any] = [
            TealiumDataKey.consentStatus: "notConsented",
            TealiumDataKey.consentCategoriesKey: [String](),
            "test": "track",
            TealiumDataKey.policyKey: "gdpr",
            TealiumDataKey.consentLastUpdated: lastUpdate!
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = track.trackDictionary
        trackWithConsentData += module.getConsentData()
        XCTAssertNotNil(trackWithConsentData[TealiumDataKey.requestUUID])
        trackWithConsentData[TealiumDataKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }

    func testAddConsentDataToTrackWhenResetConsentStatus() {
        config.consentPolicy = .gdpr
        let module = createModule(with: config)
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.resetUserConsentPreferences()
        let lastUpdate = module.consentManager?.lastConsentUpdate?.unixTimeMilliseconds
        let expected: [String: Any] = [
            TealiumDataKey.consentStatus: TealiumValue.unknown,
            TealiumDataKey.consentCategoriesKey: [String](),
            "test": "track",
            TealiumDataKey.policyKey: "gdpr",
            TealiumDataKey.consentLastUpdated: lastUpdate!
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = track.trackDictionary
        trackWithConsentData += module.getConsentData()
        XCTAssertNotNil(trackWithConsentData[TealiumDataKey.requestUUID])
        trackWithConsentData[TealiumDataKey.requestUUID] = nil
        XCTAssertTrue(NSDictionary(dictionary: expected).isEqual(to: trackWithConsentData))
    }
    
    func testAddConsentDataToTrackWhenMigratedFromLegacyStorage() {
        let module = createModule(dataLayer: MockMigratedDataLayer())
        let expected: [String: Any] = [
            TealiumDataKey.consentStatus: "consented",
            TealiumDataKey.consentCategoriesKey: [TealiumConsentCategories.affiliates.rawValue,
                                              TealiumConsentCategories.bigData.rawValue,
                                              TealiumConsentCategories.crm.rawValue,
                                              TealiumConsentCategories.engagement.rawValue],
            "test": "track",
            "policy": "gdpr"
        ]
        track = TealiumTrackRequest(data: ["test": "track"])
        var trackWithConsentData = track.trackDictionary
        trackWithConsentData += module.getConsentData()
        XCTAssertNotNil(trackWithConsentData[TealiumDataKey.requestUUID])
        trackWithConsentData[TealiumDataKey.requestUUID] = nil
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
        var trackWithConsentData = track.trackDictionary
        trackWithConsentData += module.getConsentData()
        XCTAssertNotNil(trackWithConsentData[TealiumDataKey.requestUUID])
        trackWithConsentData[TealiumDataKey.requestUUID] = nil
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
    
    func testCustomConsentPolicyStatusInfo_AddedInShouldQueue() {
        let config = testTealiumConfig
        config.consentPolicy = .custom(MockCustomConsentPolicy.self)
        let context = TestTealiumHelper.context(with: config)
        let consentManagerModule = ConsentManagerModule(context: context, delegate: nil, diskStorage: DispatchQueueMockDiskStorage(), completion: { _ in })
        let request = TealiumTrackRequest(data: [TealiumDataKey.event: "testEvent"])
        let res = consentManagerModule.shouldQueue(request: request)
        let trackInfo = res.1!
        XCTAssertNotNil(trackInfo["customConsentCategories"] as? [TealiumConsentCategories])
        XCTAssertNotNil(trackInfo["custom_consent_key"] as? String)
    }

    func testGdprConsentPolicyReturnsPartialConsentIfCategoriesAreNilOrNotFull() {
        let policyType = TealiumConsentPolicy.gdpr
        var policy = ConsentPolicyFactory.create(policyType, preferences: UserConsentPreferences(consentStatus: .unknown, consentCategories: nil))
        XCTAssertEqual(policy.consentTrackingEventName, "grant_partial_consent")
        policy.preferences = UserConsentPreferences(consentStatus: .consented, consentCategories: [.affiliates])
        XCTAssertEqual(policy.consentTrackingEventName, "grant_partial_consent")
    }

    func testGdprConsentPolicyReturnsFullConsentIfCategoriesAreFull() {
        let policyType = TealiumConsentPolicy.gdpr
        var policy = ConsentPolicyFactory.create(policyType, preferences: UserConsentPreferences(consentStatus: .consented, consentCategories: TealiumConsentCategories.all))
        XCTAssertEqual(policy.consentTrackingEventName, "grant_full_consent")
    }

    func testGdprConsentPolicyReturnsDeclinedIfStatusNotConsented() {
        let policyType = TealiumConsentPolicy.gdpr
        var policy = ConsentPolicyFactory.create(policyType, preferences: UserConsentPreferences(consentStatus: .notConsented, consentCategories: TealiumConsentCategories.all))
        XCTAssertEqual(policy.consentTrackingEventName, "decline_consent")
    }
}

extension ConsentManagerModuleTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }
    func requestDequeue(reason: String) { }
    func requestTrack(_ track: TealiumTrackRequest) { }
}
