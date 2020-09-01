//
//  ConsentManagerModuleUnitTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 03/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class ConsentManagerModuleUnitTests: XCTestCase {

    var config: TealiumConfig!
    var track: TealiumTrackRequest!
    var module: ConsentManagerModule!

    override func setUp() {
        config = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        config.consentPolicy = .gdpr
    }
    
    func testConsentManagerIsDisabledAutomatically() {
        let config2 = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        let teal = Tealium(config: config2)
        XCTAssertNil(teal.consentManager)
    }
    
    func testUpdateConfig() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        var newConfig = TealiumConfig(account: "testAccount", profile: "testProfile", environment: "testEnvironment")
        newConfig.consentPolicy = nil
        var updateRequest = TealiumUpdateConfigRequest(config: newConfig)
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        let queue = module.shouldQueue(request: batchTrack)
        XCTAssertTrue(queue.0)
        XCTAssertTrue(queue.1?["queue_reason"] as? String == "batching_enabled", "Consent Manager Module: \(#function) - Track call contained unexpected value")
    }

    func testShouldQueueAllowAuditingEvents() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.resetUserConsentPreferences()
        track = TealiumTrackRequest(data: ["test": "track"])
        let queue = module.shouldQueue(request: track)
        XCTAssertTrue(queue.0)
        XCTAssertTrue(queue.1?["queue_reason"] as? String == "consentmanager", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        XCTAssertTrue(queue.1?["tracking_consented"] as? String == "unknown", "Consent Manager Module: \(#function) - Track call contained unexpected value")
    }

    func testShouldQueueTrackingStatusTrackingAllowed() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.userConsentStatus = .notConsented
        track = TealiumTrackRequest(data: ["test": "track"])
        let drop = module.shouldDrop(request: track)
        XCTAssertTrue(drop)
    }

    func testShouldNotDropWhenTrackingAllowed() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.userConsentStatus = .consented
        track = TealiumTrackRequest(data: ["test": "track"])
        let drop = module.shouldDrop(request: track)
        XCTAssertFalse(drop)
    }

    func testShouldPurgeWhenTrackingForbidden() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.userConsentStatus = .notConsented
        track = TealiumTrackRequest(data: ["test": "track"])
        let purge = module.shouldPurge(request: track)
        XCTAssertTrue(purge)
    }

    func testShouldNotPurgeWhenTrackingAllowed() {
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.userConsentStatus = .consented
        track = TealiumTrackRequest(data: ["test": "track"])
        let purge = module.shouldPurge(request: track)
        XCTAssertFalse(purge)
    }

    func testAddConsentDataToTrackWhenConsented() {
        config.consentPolicy = .gdpr
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
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
        module = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        module.consentManager?.userConsentStatus = .consented
        module.consentManager?.resetUserConsentPreferences()
        let expected: [String: Any] = [
            ConsentKey.trackingConsentedKey: "unknown",
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

}

extension ConsentManagerModuleUnitTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) { }
    func requestDequeue(reason: String) { }
    func requestTrack(_ track: TealiumTrackRequest) { }
}
