//
//  ConsentManagerIntegrationTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 01/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import Tealium
import Foundation
import XCTest

class ConsentManagerTests: XCTestCase {
    var consentManager: TealiumConsentManager?
    let tealHelper = TestTealiumHelper()
    var expectations = [XCTestExpectation]()
    var trackData: [String: Any]?
    let maxRuns = 10 // max runs for each test
    let waiter = XCTWaiter()
    var allTestsFinished = false
    var currentTest: String = ""

    override func setUp() {
        super.setUp()
        expectations = [XCTestExpectation]()
        initState()
        allTestsFinished = false
        continueAfterFailure = false
    }

    override func tearDown() {
        super.tearDown()
        deInitState()
        allTestsFinished = false
    }

    func initState() {
        consentManager = nil
        consentManager = TealiumConsentManager()
        consentManager?.resetUserConsentPreferences()
    }

    func deInitState() {
        consentManager?.resetUserConsentPreferences()
        consentManager = nil
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

    func runMultiple(_ localExpectations: [XCTestExpectation]? = nil, _ completion: (() -> Void)) {
        for iter in 0...maxRuns {
            initState()
            completion()
            if iter == maxRuns - 1 {
                allTestsFinished = true
            }
            deInitState()
        }
        localExpectations?.forEach { expectation in
            expectation.fulfill()
        }
    }

    func testInitialConsentStatusFromConfig() {
        let expectation = self.expectation(description: "testInitialConsentStatusFromConfig")
        currentTest = "testInitialConsentStatusFromConfig"
        expectations.append(expectation)
        runMultiple(expectations) {
            let config = tealHelper.getConfig()
            config.setInitialUserConsentStatus(.consented)
            consentManager?.start(config: config, delegate: tealHelper) {
                XCTAssertFalse(self.consentManager?.consentLoggingEnabled ?? true, "Consent Manager Test: \(#function) -Auditing flag unexpectedly enabled")
                XCTAssertTrue(self.consentManager?.getUserConsentPreferences()?.consentStatus == .consented, "Consent Manager Test: \(#function) -  Incorrect initial consent status from config")
            }
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testInitialConsentCategoriesFromConfig() {
        let expectation = self.expectation(description: "testInitialConsentCategoriesFromConfig")
        currentTest = "testInitialConsentCategoriesFromConfig"
        expectations.append(expectation)
        runMultiple(expectations) {
            let config = tealHelper.getConfig()
            config.setInitialUserConsentCategories([.cdp, .analytics])
            consentManager?.start(config: config, delegate: tealHelper) {
                XCTAssertFalse(self.consentManager?.consentLoggingEnabled ?? true, "Consent Manager Test: \(#function) -Auditing flag unexpectedly enabled")
                XCTAssertTrue(self.consentManager?.getUserConsentPreferences()?.consentCategories == [.cdp, .analytics], "Consent Manager Test: \(#function) -  Incorrect initial consent categories from config.")
            }
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    // note: in some cases this test fails due to slow clearing of persistent data
    // to get around this, test has been renamed to make sure it runs first (always run in alphabetical order)
    // thoroughly tested, and comfortable that this is an issue with UserDefaults clearing slowly under test on the simulator
    func testAStartDefault() {
        let expectation = self.expectation(description: "testStartDefault")
        currentTest = "testStartDefault"
        expectations.append(expectation)
        runMultiple(expectations) {
            let config = tealHelper.newConfig()
            consentManager?.start(config: config, delegate: nil) {
                XCTAssertTrue(self.consentManager?.getUserConsentStatus() == .unknown, "Consent Manager Test: \(#function) - Incorrect initial state: " + (self.consentManager?.getUserConsentStatus().rawValue ?? ""))
            }
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testUpdatePreferencesFromConfig() {
        currentTest = "testUpdatePreferencesFromConfig"
        runMultiple {
            let config = tealHelper.newConfig()
            config.setInitialUserConsentCategories([.analytics, .cdp, .bigData])
            config.setInitialUserConsentStatus(.consented)
            consentManager?.updateConsentPreferencesFromConfig(config)
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented, "Consent Manager Test: \(#function) - Incorrect consent status")
            XCTAssertTrue(consentManager?.getUserConsentCategories() == [.analytics, .cdp, .bigData], "Consent Manager Test: \(#function) - Incorrect Consent Categories")
        }
    }

    func testConsentStoreConfigFromDictionary() {
        currentTest = "testConsentStoreConfigFromDictionary"
        runMultiple {
            let categories = ["cdp", "analytics"]
            let status = "consented"
            let consentDictionary: [String: Any] = [TealiumConsentConstants.consentCategoriesKey: categories, TealiumConsentConstants.trackingConsentedKey: status]
            var consentUserPreferences = TealiumConsentUserPreferences(consentStatus: nil, consentCategories: nil)
            consentUserPreferences.initWithDictionary(preferencesDictionary: consentDictionary)
            XCTAssertNotNil(consentUserPreferences, "Consent Manager Test: \(#function) - Consent Preferences could not be initialized from dictionary")
            XCTAssertTrue(consentUserPreferences.consentStatus == .consented, "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
            XCTAssertTrue(consentUserPreferences.consentCategories == [.cdp, .analytics], "Consent Manager Test: \(#function) - Consent Preferences contained unexpected status")
        }
    }

    func testTrackUserConsentPreferences() {
        let expectation = self.expectation(description: "testTrackUserConsentPreferences")
        currentTest = "testTrackUserConsentPreferences"
        expectations.append(expectation)
        runMultiple {
            consentManager?.setModuleDelegate(delegate: self)
            consentManager?.consentLoggingEnabled = true
            let consentPreferences = TealiumConsentUserPreferences(consentStatus: .consented, consentCategories: [.cdp])
            consentManager?.trackUserConsentPreferences(preferences: consentPreferences)
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testloadSavedPreferencesEmpty() {
        currentTest = "testloadSavedPreferencesEmpty"
        runMultiple {
            let preferencesConfig = consentManager?.getSavedPreferences()
            XCTAssertTrue(preferencesConfig == nil, "Consent Manager Test: \(#function) -Preferences unexpectedly contained a value")
        }
    }

    // check that persistent saved preferences contains values passed in config object
    func testloadSavedPreferencesExistingPersistentData() {
        currentTest = "testloadSavedPreferencesFull"
        let config = tealHelper.newConfig()
        let expectation = self.expectation(description: "testloadSavedPreferencesFull")
        expectations.append(expectation)
        runMultiple(expectations) {
            config.setInitialUserConsentStatus(.consented)
            config.setInitialUserConsentCategories([.cdp, .analytics])
            consentManager?.start(config: config, delegate: nil) {
                if let savedConfig = self.consentManager?.getSavedPreferences() {
                    let categories = savedConfig.consentCategories, status = savedConfig.consentStatus
                    XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
                    XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
                }
            }
        }

        waiter.wait(for: expectations, timeout: 100)
    }

    // note: can sometimes fail when run with other tests due to multiple resets being in queue
    // this is not believed to be a problem; it runs fine in isolation.
    // extensively tested
    func testStoreUserConsentPreferences() {
        currentTest = "testStoreUserConsentPreferences"
        runMultiple {
            let preferences = TealiumConsentUserPreferences(consentStatus: .consented, consentCategories: [.cdp, .analytics])
            consentManager?.setConsentUserPreferences(preferences)
            consentManager?.storeConsentUserPreferences()
            let savedPreferences = consentManager?.getSavedPreferences()
            if let categories = savedPreferences?.consentCategories, let status = savedPreferences?.consentStatus {
                XCTAssertTrue(categories == [.cdp, .analytics], "Consent Manager Test: \(#function) -Incorrect array members found for categories")
                XCTAssertTrue(status == .consented, "Consent Manager Test: \(#function) -Incorrect consent status found")
            } else {
                XCTFail("Saved consent preferences was nil")
            }
        }
    }

    func testCanUpdateCategories() {
        let expectation = self.expectation(description: "testCanUpdateCategories")
        currentTest = "testCanUpdateCategories"
        expectations.append(expectation)
        runMultiple(expectations) {
            consentManager?.resetUserConsentPreferences()
            let config = tealHelper.getConfig()
            config.setInitialUserConsentCategories([.cdp, .analytics])
            consentManager?.start(config: config, delegate: tealHelper) {
                self.consentManager?.setUserConsentCategories([.bigData])
                XCTAssertTrue(self.consentManager?.getSavedPreferences()?.consentCategories == [.bigData])
            }
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testCanUpdateStatus() {
        let expectation = self.expectation(description: "testCanUpdateStatus")
        currentTest = "testCanUpdateStatus"
        expectations.append(expectation)
        runMultiple(expectations) {
            consentManager?.resetUserConsentPreferences()
            let config = tealHelper.getConfig()
            config.setInitialUserConsentStatus(.consented)
            consentManager?.start(config: config, delegate: tealHelper) {
                self.consentManager?.setUserConsentStatus(.notConsented)
                XCTAssertTrue(self.consentManager?.getSavedPreferences()?.consentStatus == .notConsented)
            }
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testGetTrackingStatus() {
        currentTest = "testGetTrackingStatus"
        let expectation = self.expectation(description: "testGetTrackingStatus")
        expectations.append(expectation)
        runMultiple(expectations) {
            let config = tealHelper.newConfig()
            config.setInitialUserConsentStatus(.notConsented)
            config.setInitialUserConsentCategories([.cdp, .analytics])
            consentManager?.start(config: config, delegate: nil) {
                if let _ = self.consentManager?.getSavedPreferences() {
                    XCTAssertTrue(self.consentManager?.getTrackingStatus() == .trackingForbidden, "Consent Manager Test: \(#function) - getTrackingStatus returned unexpected value")
                }
            }
        }

        waiter.wait(for: expectations, timeout: 100)
    }

    func testSetConsentStatus() {
        currentTest = "testSetConsentStatus"
        runMultiple {
            consentManager?.setUserConsentStatus(.notConsented)
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .notConsented, "Consent Manager Test: \(#function) - unexpected consent status")
            XCTAssertTrue(consentManager?.getUserConsentCategories() == [TealiumConsentCategories](), "Consent Manager Test: \(#function) - unexpectedly found consent categories")
        }
    }

    func testSetConsentCategories() {
        currentTest = "testSetConsentCategories"
        runMultiple {
            consentManager?.setUserConsentCategories([.affiliates])
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented, "Consent Manager Test: \(#function) - unexpected consent status")
            XCTAssertTrue(consentManager?.getUserConsentCategories() == [.affiliates], "Consent Manager Test: \(#function) -  unexpected consent categories found")
        }
    }

    func testSetConsentStatusWithCategories() {
        currentTest = "testSetConsentStatusWithCategories"
        runMultiple {
            consentManager?.setUserConsentStatusWithCategories(status: .consented, categories: [.affiliates])
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented, "Consent Manager Test: \(#function) - unexpected consent status")
            XCTAssertTrue(consentManager?.getUserConsentCategories() == [.affiliates], "Consent Manager Test: \(#function) - unexpected consent categories found")
        }
    }

    func testGetUserConsentStatusInitialStatus() {
        currentTest = "testGetUserConsentStatusInitialStatus"
        runMultiple {
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .unknown, "Consent Manager Test: \(#function) - unexpected consent status")
        }
    }

    func testGetUserConsentCategoriesInitialStatus() {
        currentTest = "testGetUserConsentCategoriesInitialStatus"
        runMultiple {
            XCTAssertTrue(consentManager?.getUserConsentCategories() == nil, "Consent Manager Test: \(#function) - unexpected consent categories found")
        }
    }

    func testResetUserConsentPreferences() {
        currentTest = "testResetUserConsentPreferences"
        runMultiple {
            consentManager?.setUserConsentStatusWithCategories(status: .consented, categories: [.cdp])
            consentManager?.resetUserConsentPreferences()
            XCTAssertTrue(consentManager?.getSavedPreferences() == nil, "Consent Manager Test: \(#function) - unexpected config found")
            XCTAssertTrue(consentManager?.getUserConsentStatus() == .unknown, "Consent Manager Test: \(#function) - unexpected status found")
            XCTAssertTrue(consentManager?.getUserConsentCategories() == nil, "Consent Manager Test: \(#function) - unexpected categories found")
        }
    }

    func testResetUserConsentPreferencesTriggersConsentStatusChanged() {
        let expectation = self.expectation(description: "testResetUserConsentPreferencesTriggersConsentStatusChanged")
        expectations.append(expectation)
        runMultiple {
            currentTest = "testResetUserConsentPreferencesTriggersConsentStatusChanged"
            consentManager?.setUserConsentStatusWithCategories(status: .consented, categories: [.cdp])
            consentManager?.addConsentDelegate(self)
            consentManager?.resetUserConsentPreferences()
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testResetUserConsentPreferencesTriggersConsentCategoriesChanged() {
        let expectation = self.expectation(description: "testResetUserConsentPreferencesTriggersConsentCategoriesChanged")
        expectations.append(expectation)
        runMultiple {
            currentTest = "testResetUserConsentPreferencesTriggersConsentCategoriesChanged"
            consentManager?.setUserConsentStatusWithCategories(status: .consented, categories: [.cdp])
            consentManager?.addConsentDelegate(self)
            consentManager?.resetUserConsentPreferences()
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    // MARK: Delegate Tests

    func testDelegateConsentStatusChanged() {
        let expectation = self.expectation(description: "testDelegateConsentStatusChanged")
        expectations.append(expectation)
        runMultiple {
            consentManager?.setUserConsentStatus(.consented)
            consentManager?.addConsentDelegate(self)
            currentTest = "testDelegateConsentStatusChanged"
            consentManager?.setUserConsentStatus(.unknown)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateUserOptedOutOfTracking() {
        let expectation = self.expectation(description: "testDelegateUserOptedOutOfTracking")
        expectations.append(expectation)
        runMultiple {
            consentManager?.setUserConsentStatus(.consented)
            consentManager?.addConsentDelegate(self)
            currentTest = "testDelegateUserOptedOutOfTracking"
            consentManager?.setUserConsentStatus(.notConsented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateUserConsentedToTracking() {
        let expectation = self.expectation(description: "testDelegateUserConsentedToTracking")
        expectations.append(expectation)
        runMultiple {
            consentManager?.setUserConsentStatus(.notConsented)
            consentManager?.addConsentDelegate(self)
            currentTest = "testDelegateUserConsentedToTracking"
            consentManager?.setUserConsentStatus(.consented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateUserChangedConsentCategories() {
        let expectation = self.expectation(description: "testDelegateUserChangedConsentCategories")
        expectations.append(expectation)
        runMultiple {
            consentManager?.setUserConsentCategories([.bigData, .analytics, .cdp])
            consentManager?.addConsentDelegate(self)
            currentTest = "testDelegateUserChangedConsentCategories"
            consentManager?.setUserConsentCategories([.analytics, .bigData])
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateWillDropTrackingCall() {
        let expectation = self.expectation(description: "testDelegateWillDropTrackingCall")
        expectations.append(expectation)
        runMultiple {
            let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
            let consentManagerModule = TealiumConsentManagerModule(delegate: nil)
            let localConsentManager = consentManagerModule.consentManager
            localConsentManager.setUserConsentStatus(.notConsented)
            localConsentManager.addConsentDelegate(self)
            currentTest = "testDelegateWillDropTrackingCall"
            consentManagerModule.isEnabled = true
            consentManagerModule.ready = true
            consentManagerModule.track(track)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateWillQueueTrackingCall() {
        let expectation = self.expectation(description: "testDelegateWillQueueTrackingCall")
        expectations.append(expectation)
        runMultiple {
            let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
            let consentManagerModule = TealiumConsentManagerModule(delegate: nil)
            let localConsentManager = consentManagerModule.consentManager
            localConsentManager.setUserConsentStatus(.unknown)
            localConsentManager.addConsentDelegate(self)
            currentTest = "testDelegateWillQueueTrackingCall"
            consentManagerModule.isEnabled = true
            consentManagerModule.ready = true
            consentManagerModule.track(track)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testDelegateWillSendTrackingCall() {
        let expectation = self.expectation(description: "testDelegateWillSendTrackingCall")
        expectations.append(expectation)
        runMultiple {
            let track = TealiumTrackRequest(data: ["dummy": "true"], completion: nil)
            let consentManagerModule = TealiumConsentManagerModule(delegate: nil)
            let localConsentManager = consentManagerModule.consentManager
            localConsentManager.setUserConsentStatus(.consented)
            localConsentManager.addConsentDelegate(self)
            currentTest = "testDelegateWillSendTrackingCall"
            consentManagerModule.isEnabled = true
            consentManagerModule.ready = true
            consentManagerModule.track(track)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    // MARK: Consent Convenience Methods

    func testConsentStatusConsentedSetsAllCategoryNames() {
        consentManager?.setUserConsentStatus(.consented)
        XCTAssertTrue(consentManager?.getUserConsentCategories() == TealiumConsentCategories.all())
        XCTAssertTrue(consentManager?.getUserConsentCategories()?.count == TealiumConsentCategories.all().count)
    }

    func testNotConsentedRemovesAllCategoryNames() {
        consentManager?.setUserConsentStatus(.consented)
        consentManager?.setUserConsentStatus(.notConsented)
        XCTAssertTrue(consentManager?.getUserConsentCategories()?.count == 0)
    }

    func testConsentStatusIsConsentedIfCategoriesAreSet() {
        consentManager?.setUserConsentStatus(.notConsented)
        consentManager?.setUserConsentCategories([.analytics])
        XCTAssertTrue(consentManager?.getUserConsentStatus() == .consented)
    }
}

extension ConsentManagerTests: TealiumConsentManagerDelegate {

    func willDropTrackingCall(_ request: TealiumTrackRequest) {
        if allTestsFinished {
            getExpectation(forDescription: "testDelegateWillDropTrackingCall")?.fulfill()
        }
    }

    func willQueueTrackingCall(_ request: TealiumTrackRequest) {
        if allTestsFinished {
            getExpectation(forDescription: "testDelegateWillQueueTrackingCall")?.fulfill()
        }
    }

    func willSendTrackingCall(_ request: TealiumTrackRequest) {
        if allTestsFinished {
            getExpectation(forDescription: "testDelegateWillSendTrackingCall")?.fulfill()
        }
    }

    func consentStatusChanged(_ status: TealiumConsentStatus) {
        if currentTest == "testDelegateConsentStatusChanged" {
            guard status == .unknown else {
                return
            }
            if allTestsFinished {
                XCTAssertTrue(status == .unknown)
                getExpectation(forDescription: "testDelegateConsentStatusChanged")?.fulfill()
            }
        } else if currentTest == "testResetUserConsentPreferencesTriggersConsentStatusChanged" {
            XCTAssertTrue(status == .unknown)
            if allTestsFinished {
                getExpectation(forDescription: "testResetUserConsentPreferencesTriggersConsentStatusChanged")?.fulfill()
            }
        }
    }

    func userConsentedToTracking() {
        if allTestsFinished {
            getExpectation(forDescription: "testDelegateUserConsentedToTracking")?.fulfill()
        }
    }

    func userOptedOutOfTracking() {
        if allTestsFinished {
            getExpectation(forDescription: "testDelegateUserOptedOutOfTracking")?.fulfill()
        }
    }

    func userChangedConsentCategories(categories: [TealiumConsentCategories]) {
        // ensure this is only invoked on the intended test
        if currentTest == "testDelegateUserChangedConsentCategories" {
            if allTestsFinished {
                XCTAssertTrue(categories == [.analytics, .bigData], "Consent Manager Test: \(#function) - unexpected categories found")
                getExpectation(forDescription: "testDelegateUserChangedConsentCategories")?.fulfill()
            }
        } else if currentTest == "testResetUserConsentPreferencesTriggersConsentCategoriesChanged" {
            if allTestsFinished {
                XCTAssertTrue(categories.count == 0, "Consent Manager Test: \(#function) - unexpected categories found")
                getExpectation(forDescription: "testResetUserConsentPreferencesTriggersConsentCategoriesChanged")?.fulfill()
            }
        }
    }
}

extension ConsentManagerTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            trackData = process.data
            if trackData?["tealium_event"] as? String == TealiumKey.updateConsentCookieEventName {
                return
            }
            if let testtrackUserConsentPreferencesExpectation = getExpectation(forDescription: "testTrackUserConsentPreferences") {
                if let categories = trackData?["consent_categories"] as? [String] {
                    let catEnum = TealiumConsentCategories.consentCategoriesStringArrayToEnum(categories)
                    XCTAssertTrue([TealiumConsentCategories.cdp] == catEnum, "Consent Manager Test: testTrackUserConsentPreferences: Categories array contained unexpected values")
                }
                if allTestsFinished {
                    testtrackUserConsentPreferencesExpectation.fulfill()
                }
            }
        }
    }
}
