//
//  ConsentManagerModuleUnitTests.swift
//  tealium-swift
//
//  Created by Craig Rouse on 03/05/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import Tealium
import Foundation
import XCTest

class ConsentManagerModuleUnitTests: XCTestCase {

    var expectations = [XCTestExpectation]()
    let waiter = XCTWaiter()
    var currentTest = ""
    var allTestsFinished = false
    let maxRuns = 10 // max runs for each test

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
            completion()
            if iter == maxRuns - 1 {
                allTestsFinished = true
            }
        }
        localExpectations?.forEach { expectation in
            expectation.fulfill()
        }
    }

    override func setUp() {
        super.setUp()
        allTestsFinished = false
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        allTestsFinished = false
    }

    func testMinimumProtocolsReturn() {
        currentTest = "\(#function)"
        let helper = TestTealiumHelper()
        let module = TealiumConsentManagerModule(delegate: nil)
        helper.modulesReturnsMinimumProtocols(module: module) { success, failingProtocols in
            // track is expected to fail
            let successful = success || (!success && failingProtocols == ["track"])
            XCTAssertTrue(successful, "Not all protocols returned. Failing protocols: \(failingProtocols)")
        }
    }

    func testConsentManagerDisabled() {
        currentTest = "testConsentManagerDisabled"
        self.expectations.append(expectation(description: "consentManagerDisabled"))
        let module = TealiumConsentManagerModule(delegate: self)
        module.isEnabled = false
        let track = TealiumTrackRequest(data: ["consent_disabled": "true"], completion: nil)
        module.track(track)
        waiter.wait(for: expectations, timeout: 20)
    }

    // MARK: Queue Tests

    func testPurgeQueueOnConsentDeclined() {
        expectations.append(expectation(description: "testPurgeQueueOnConsentDeclined"))
        runMultiple {
            currentTest = "testPurgeQueueOnConsentDeclined"
            let helper = TestTealiumHelper()
            let config = helper.getConfig()

            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            let track = TealiumTrackRequest(data: ["purge_test": "true"], completion: nil)
            module.track(track)
            module.consentManager.setUserConsentStatus(.notConsented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testReleaseQueueOnConsentGranted() {
        expectations.append(expectation(description: "testReleaseQueueOnConsentGranted"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            // set currentTest here to avoid triggering ReleaseQueue at module enable (avoid multiple fulfill on expectation)
            currentTest = "testReleaseQueueOnConsentGranted"
            let track = TealiumTrackRequest(data: ["release_test": "true"], completion: nil)
            module.track(track)
            module.consentManager.setUserConsentStatus(.consented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    // MARK: Consent Logging Tests

    func testConsentLoggingFullConsent() {
        expectations.append(expectation(description: "testConsentLoggingFullConsent"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            config.setConsentLoggingEnabled(true)
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            currentTest = "testConsentLoggingFullConsent"
            module.consentManager.setUserConsentStatus(.consented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testConsentLoggingPartialConsent() {
        expectations.append(expectation(description: "testConsentLoggingPartialConsent"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            config.setConsentLoggingEnabled(true)
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            currentTest = "testConsentLoggingPartialConsent"
            module.consentManager.setUserConsentCategories([.analytics, .cdp])
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testUpdateConsentCookieFullConsent() {
        expectations.append(expectation(description: "testUpdateConsentCookieFullConsent"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            config.setConsentLoggingEnabled(true)
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            currentTest = "testUpdateConsentCookieFullConsent"
            module.consentManager.setUserConsentStatus(.consented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testUpdateConsentCookiePartialConsent() {
        expectations.append(expectation(description: "testUpdateConsentCookiePartialConsent"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            config.setConsentLoggingEnabled(true)
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            currentTest = "testUpdateConsentCookiePartialConsent"
            module.consentManager.setUserConsentCategories([.analytics, .cdp])
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }

    func testUpdateConsentCookieDeclineConsent() {
        expectations.append(expectation(description: "testUpdateConsentCookieDeclineConsent"))
        runMultiple {
            let helper = TestTealiumHelper()
            let config = helper.getConfig()
            config.setConsentLoggingEnabled(false)
            let module = TealiumConsentManagerModule(delegate: self)
            module.consentManager.resetUserConsentPreferences()
            let enableRequest = TealiumEnableRequest(config: config, enableCompletion: nil)
            module.enable(enableRequest)
            currentTest = "testUpdateConsentCookieDeclineConsent"
            module.consentManager.setUserConsentStatus(.notConsented)
            currentTest = ""
        }
        waiter.wait(for: expectations, timeout: 100)
    }
}

extension ConsentManagerModuleUnitTests: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        if let process = process as? TealiumTrackRequest {
            let trackData = process.data
            if trackData["consent_disabled"] as? String == "true" {
                XCTAssertTrue(trackData["consent_categories"] == nil, "Consent Manager Module: \(#function) - Consent Categories unexpectedly found in track call")
                XCTAssertTrue(trackData["was_queued"] == nil, "Consent Manager Module: \(#function) - Track call contained unexpected value")
                self.getExpectation(forDescription: "consentManagerDisabled")?.fulfill()
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {
        if let process = process as? TealiumEnqueueRequest, currentTest == "testPurgeQueueOnConsentDeclined" {
            let trackRequest = process.data, trackData = trackRequest.data
            XCTAssertTrue(trackData["purge_test"] as? String == "true", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        } else if let _ = process as? TealiumClearQueuesRequest, currentTest == "testPurgeQueueOnConsentDeclined" {
            if allTestsFinished {
                self.getExpectation(forDescription: "testPurgeQueueOnConsentDeclined")?.fulfill()
            }
        } else if let process = process as? TealiumEnqueueRequest, currentTest == "testReleaseQueueOnConsentGranted" {
            let trackRequest = process.data, trackData = trackRequest.data
            XCTAssertTrue(trackData["release_test"] as? String == "true", "Consent Manager Module: \(#function) - Track call contained unexpected value")
        } else if let _ = process as? TealiumReleaseQueuesRequest, currentTest == "testReleaseQueueOnConsentGranted" {
            if allTestsFinished {
                self.getExpectation(forDescription: "testReleaseQueueOnConsentGranted")?.fulfill()
            }
        } else if let process = process as? TealiumTrackRequest, currentTest == "testConsentLoggingFullConsent" {
            let trackRequest = process.data
            if trackRequest[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName {
                return
            }
            XCTAssertTrue(trackRequest[TealiumKey.event] as? String == TealiumConsentConstants.consentGrantedEventName, "Consent Manager Module: \(#function) - Track call contained unexpected event name")
            XCTAssertTrue((trackRequest[TealiumConsentConstants.consentCategoriesKey] as? [String])?.count == TealiumConsentCategories.all().count, "Consent Manager Module: \(#function) - Track call contained unexpected event categories")
            if allTestsFinished {
                getExpectation(forDescription: "testConsentLoggingFullConsent")?.fulfill()
            }
        } else if let process = process as? TealiumTrackRequest, currentTest == "testConsentLoggingPartialConsent" {
            let trackRequest = process.data
            if trackRequest[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName {
                return
            }
            XCTAssertTrue(trackRequest[TealiumKey.event] as? String == TealiumConsentConstants.consentPartialEventName, "Consent Manager Module: \(#function) - Track call contained unexpected event name")
            XCTAssertTrue(trackRequest[TealiumConsentConstants.consentCategoriesKey] as? [String] == ["analytics", "cdp"], "Consent Manager Module: \(#function) - Track call contained unexpected event categories")
            if allTestsFinished {
                getExpectation(forDescription: "testConsentLoggingPartialConsent")?.fulfill()
            }
        } else if let process = process as? TealiumTrackRequest, currentTest == "testUpdateConsentCookieFullConsent" {
            let trackRequest = process.data
            if trackRequest[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName {
                return
            }
            XCTAssertTrue(trackRequest[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName, "Consent Manager Module: \(#function) - Track call contained unexpected event name")
            XCTAssertTrue((trackRequest[TealiumConsentConstants.consentCategoriesKey] as? [String])?.count == TealiumConsentCategories.all().count, "Consent Manager Module: \(#function) - Track call contained unexpected event categories")
            if allTestsFinished {
                getExpectation(forDescription: "testUpdateConsentCookieFullConsent")?.fulfill()
            }
        } else if let process = process as? TealiumTrackRequest, currentTest == "testUpdateConsentCookiePartialConsent" {
            let trackRequest = process.data
            if trackRequest[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName {
                return
            }
            XCTAssertTrue(trackRequest[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName, "Consent Manager Module: \(#function) - Track call contained unexpected event name")
            XCTAssertTrue(trackRequest[TealiumConsentConstants.consentCategoriesKey] as? [String] == ["analytics", "cdp"], "Consent Manager Module: \(#function) - Track call contained unexpected event categories")
            if allTestsFinished {
                getExpectation(forDescription: "testUpdateConsentCookiePartialConsent")?.fulfill()
            }
        } else if let process = process as? TealiumTrackRequest, currentTest == "testUpdateConsentCookieDeclineConsent" {
            let trackRequest = process.data
            if trackRequest[TealiumKey.event] as? String != TealiumKey.updateConsentCookieEventName {
                return
            }
            XCTAssertTrue(trackRequest[TealiumKey.event] as? String == TealiumKey.updateConsentCookieEventName, "Consent Manager Module: \(#function) - Track call contained unexpected event name")
            XCTAssertTrue((trackRequest[TealiumConsentConstants.consentCategoriesKey] as? [String])?.count == 0, "Consent Manager Module: \(#function) - Track call contained unexpected event categories")
            if allTestsFinished {
                getExpectation(forDescription: "testUpdateConsentCookieDeclineConsent")?.fulfill()
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
}
