//
//  ConsentManagerIntegrationTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 01/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class ConsentManagerTests: XCTestCase {
    var consentManager: ConsentManager {
        let config = self.config!
        return ConsentManager(config: config, delegate: self, diskStorage: ConsentMockDiskStorage())
    }
    
    var consentManagerEmptyDelegate: ConsentManager {
        let config = self.config!
        return ConsentManager(config: config, delegate: ConsentManagerDelegate(), diskStorage: ConsentMockDiskStorage())
    }
    
    var consentManagerCCPA: ConsentManager {
        let config = self.config!
        config.consentPolicy = .ccpa
        return ConsentManager(config: config, delegate: ConsentManagerDelegate(), diskStorage: ConsentMockDiskStorage())
    }
    
    func consentManagerForConfig(_ config: TealiumConfig) -> ConsentManager {
        return ConsentManager(config: config, delegate: ConsentManagerDelegate(), diskStorage: ConsentMockDiskStorage())
    }
    
    
    let tealHelper = TestTealiumHelper()
    var config: TealiumConfig!
    var expectations = [XCTestExpectation]()
    var trackData: [String: Any]?
    let waiter = XCTWaiter()
    var allTestsFinished = false

    override func setUp() {
        super.setUp()
        expectations = [XCTestExpectation]()
        config = tealHelper.getConfig()
    }

    override func tearDown() {
        super.tearDown()
    }

    func getExpectation(forDescription: String) -> XCTestExpectation? {
        let exp = expectations.filter {
            $0.description == forDescription
        }
        if exp.count > 0 {
            return exp[0]
        }
        return nil
    }

    // note: in some cases this test fails due to slow clearing of persistent data
    // to get around this, test has been renamed to make sure it runs first (always run in alphabetical order)
    // thoroughly tested, and comfortable that this is an issue with UserDefaults clearing slowly under test on the simulator
    func testAStartDefault() {
        let consentManager = consentManagerEmptyDelegate
        XCTAssertTrue(consentManager.userConsentStatus == .unknown, "Consent Manager Test: \(#function) - Incorrect initial state: " + (self.consentManager.userConsentStatus.rawValue))
    }

    func testConsentStoreConfigFromDictionary() {
        let categories = ["cdp", "analytics"]
        let status = "consented"
        let consentDictionary: [String: Any] = [ConsentKey.consentCategoriesKey: categories, ConsentKey.trackingConsentedKey: status]
        var userConsentPreferences = UserConsentPreferences(consentStatus: .unknown, consentCategories: nil)
        userConsentPreferences.initWithDictionary(preferencesDictionary: consentDictionary)
        XCTAssertNotNil(userConsentPreferences, "Consent Manager Test: \(#function) - Consent Preferences could not be initialized from dictionary")
        XCTAssertTrue(userConsentPreferences.consentStatus == .consented, "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
        XCTAssertTrue(userConsentPreferences.consentCategories == [.cdp, .analytics], "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
    }

    func testTrackUserConsentPreferences() {
        let config = testTealiumConfig
        config.consentLoggingEnabled = true
        let consentManager = consentManagerForConfig(config)
        let expectation = self.expectation(description: "testTrackUserConsentPreferences")
        expectations.append(expectation)
        let consentPreferences = UserConsentPreferences(consentStatus: .consented, consentCategories: [.cdp])
        consentManager.trackUserConsentPreferences(consentPreferences)
        waiter.wait(for: expectations, timeout: 2)
    }

    func testloadSavedPreferencesEmpty() {
        let consentManager = consentManagerEmptyDelegate
        let preferencesConfig = consentManager.consentPreferencesStorage?.preferences
        XCTAssertTrue(preferencesConfig == nil, "Consent Manager Test: \(#function) -Preferences unexpectedly contained a value")
    }

    // check that persistent saved preferences contains values passed in config object
    func testloadSavedPreferencesExistingPersistentData() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .consented
        consentManager.userConsentCategories = [.cdp, .analytics]
        if let savedConfig = consentManager.consentPreferencesStorage?.preferences {
            let categories = savedConfig.consentCategories, status = savedConfig.consentStatus
            XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
            XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
        }
    }

    // note: can sometimes fail when run with other tests due to multiple resets being in queue
    // this is not believed to be a problem; it runs fine in isolation.
    // extensively tested
    func testStoreUserConsentPreferences() {
        let consentManager = consentManagerEmptyDelegate
        let preferences = UserConsentPreferences(consentStatus: .consented, consentCategories: [.cdp, .analytics])
        consentManager.storeUserConsentPreferences(preferences)
        let savedPreferences = consentManager.consentPreferencesStorage?.preferences
        if let categories = savedPreferences?.consentCategories, let status = savedPreferences?.consentStatus {
            XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
            XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
        } else {
            XCTFail("Saved consent preferences was nil")
        }
    }

    func testCanUpdateCategories() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.resetUserConsentPreferences()
        consentManager.userConsentCategories = [.cdp, .analytics]
        XCTAssertTrue(consentManager.consentPreferencesStorage?.preferences?.consentCategories == [.cdp, .analytics])
        consentManager.userConsentCategories = [.bigData]
        XCTAssertTrue(consentManager.consentPreferencesStorage?.preferences?.consentCategories == [.bigData])
    }

    func testCanUpdateStatus() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.resetUserConsentPreferences()
        consentManager.userConsentStatus = .consented
        consentManager.userConsentStatus = .notConsented
        XCTAssertTrue(consentManager.consentPreferencesStorage?.preferences?.consentStatus == .notConsented)
    }

    func testGetTrackingStatusWhenNotConsented() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .notConsented
        if let _ = consentManager.consentPreferencesStorage?.preferences {
            XCTAssertTrue(consentManager.trackingStatus == .trackingForbidden, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
        }
    }
    
    func testGetTrackingStatusWhenNotConsentedCCPA() {
        let consentManager = consentManagerCCPA
        consentManager.userConsentStatus = .notConsented
        if let _ = consentManager.consentPreferencesStorage?.preferences {
            XCTAssertTrue(consentManager.trackingStatus == .trackingAllowed, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
        }
    }

    func testGetTrackingStatusWhenConsented() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentCategories = [.analytics, .cookieMatch]
        if let _ = consentManager.consentPreferencesStorage?.preferences {
            XCTAssertTrue(consentManager.trackingStatus == .trackingAllowed, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
        }
    }

    func testSetConsentStatus() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .notConsented
        XCTAssertTrue(consentManager.userConsentStatus == .notConsented, "Consent Manager Test: \(#function) - unexpected consent status")
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories! == [TealiumConsentCategories](), "Consent Manager Test: \(#function) - unexpectedly found consent categories")
    }

    func testSetConsentCategories() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentCategories = [.affiliates]
        XCTAssertTrue(consentManager.userConsentStatus == .consented, "Consent Manager Test: \(#function) - unexpected consent status")
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories! == [.affiliates], "Consent Manager Test: \(#function) -  unexpected consent categories found")
    }

    func testResetUserConsentPreferences() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .consented
        consentManager.userConsentCategories = [.cdp]
        consentManager.resetUserConsentPreferences()
        XCTAssertTrue(consentManager.consentPreferencesStorage?.preferences == nil, "Consent Manager Test: \(#function) - unexpected config found")
        XCTAssertTrue(consentManager.userConsentStatus == .unknown, "Consent Manager Test: \(#function) - unexpected status found")
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories == nil, "Consent Manager Test: \(#function) - unexpected categories found")
    }

    func testShouldDropTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"])
        config.consentPolicy = .gdpr
        let consentManagerModule = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        consentManagerModule.consentManager = consentManagerEmptyDelegate
        consentManagerModule.consentManager?.userConsentStatus = .notConsented
        let shouldDrop = consentManagerModule.shouldDrop(request: track)
        XCTAssertTrue(shouldDrop)
    }
    
    func testShouldDropTrackingCallCCPA() {
        let track = TealiumTrackRequest(data: ["dummy": "true"])
        config.consentPolicy = .ccpa
        let consentManagerModule = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        consentManagerModule.consentManager = consentManagerCCPA
        consentManagerModule.consentManager?.userConsentStatus = .notConsented
        let shouldDrop = consentManagerModule.shouldDrop(request: track)
        XCTAssertFalse(shouldDrop)
    }

    func testShouldQueueTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"])
        config.consentPolicy = .gdpr
        let consentManagerModule = ConsentManagerModule(config: config, delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        consentManagerModule.consentManager = consentManagerCCPA
        let localConsentManager = consentManagerModule.consentManager
        localConsentManager?.userConsentStatus = .unknown
        let queue = consentManagerModule.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
    }

    func testShouldNotQueueTrackingCall() {
        let track = TealiumTrackRequest(data: ["dummy": "true"])
        let consentManagerModule = ConsentManagerModule(config: TestTealiumHelper().getConfig(), delegate: self, diskStorage: ConsentMockDiskStorage(), completion: { _ in })
        consentManagerModule.consentManager = consentManagerEmptyDelegate
        let localConsentManager = consentManagerModule.consentManager
        localConsentManager?.userConsentStatus = .consented
        let queue = consentManagerModule.shouldQueue(request: track)
        XCTAssertFalse(queue.0)
    }

    // MARK: Consent Convenience Methods
    func testConsentStatusConsentedSetsAllCategoryNames() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .consented
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories! == TealiumConsentCategories.all)
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories!.count == TealiumConsentCategories.all.count)
    }

    func testNotConsentedRemovesAllCategoryNames() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .consented
        consentManager.userConsentStatus = .notConsented
        guard let categories = consentManager.currentPolicy.preferences.consentCategories else {
            XCTFail("Categories should return at least empty array")
            return
        }
        XCTAssertTrue(categories.isEmpty)
    }

    func testConsentStatusIsConsentedIfCategoriesAreSet() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentStatus = .notConsented
        consentManager.userConsentCategories = [.analytics]
        XCTAssertTrue(consentManager.userConsentStatus == .consented)
    }

    func testConsentStatusIsUknownIfNoStatusSet() {
        let consentManager = consentManagerEmptyDelegate
        XCTAssertTrue(consentManager.userConsentStatus == .unknown)
    }

    func testGetUserConsentCategoriesOnceSet() {
        let consentManager = consentManagerEmptyDelegate
        consentManager.userConsentCategories = [.analytics, .bigData]
        XCTAssertTrue(consentManager.currentPolicy.preferences.consentCategories! == [.analytics, .bigData])
    }

    func testSetUserConsentPreferences() {
        let consentManager = consentManagerEmptyDelegate
        let expectedUserConsentPreferences = UserConsentPreferences(consentStatus: .consented, consentCategories: [.analytics, .engagement])
        consentManager.currentPolicy.preferences = expectedUserConsentPreferences
        let actualUserConsentPreferences = consentManager.currentPolicy.preferences
        XCTAssertEqual(actualUserConsentPreferences, expectedUserConsentPreferences)
    }
}

extension ConsentManagerTests: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        
    }
    
    func requestDequeue(reason: String) { }

    func requestTrack(_ track: TealiumTrackRequest) {
        trackData = track.trackDictionary
        if trackData?["tealium_event"] as? String == ConsentKey.gdprConsentCookieEventName {
            return
        }
        if let testtrackUserConsentPreferencesExpectation = getExpectation(forDescription: "testTrackUserConsentPreferences") {
            if let categories = trackData?["consent_categories"] as? [String], categories.count > 0 {
                let catEnum = TealiumConsentCategories.consentCategoriesStringArrayToEnum(categories)
                XCTAssertTrue([TealiumConsentCategories.cdp] == catEnum, "Consent Manager Test: testTrackUserConsentPreferences: Categories array contained unexpected values")
            }
            if allTestsFinished {
                testtrackUserConsentPreferencesExpectation.fulfill()
            }
        }
    }

}

class ConsentManagerDelegate: ModuleDelegate {
    func requestDequeue(reason: String) {
        
    }
    
    func processRemoteCommandRequest(_ request: TealiumRequest) {
        
    }
    

    func requestTrack(_ track: TealiumTrackRequest) {
        
    }
}
