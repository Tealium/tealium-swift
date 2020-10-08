//
//  TealiumExtensionTests.swift
//  TealiumAppDelegateProxyTests-iOS
//
//  Created by Christina S on 10/2/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCollect
@testable import TealiumCore
@testable import TealiumLifecycle
@testable import TealiumVisitorService
#if os(iOS)
@testable import TealiumAutotracking
@testable import TealiumLocation
@testable import TealiumRemoteCommands
@testable import TealiumTagManagement
#endif

import XCTest

class TealiumExtensionTests: XCTestCase {

    var defaultTealiumConfig = TealiumConfig(account: "tealiummobile",
                                             profile: "demo",
                                             environment: "dev",
                                             options: nil)

    var tealium: Tealium!

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws { }

    func testVisitorIdNotNil() {
        let expect = expectation(description: "Visitor id not nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.visitorId)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testConsentManagerNotNil() {
        let expect = expectation(description: "Consent Manager Module not nil")
        defaultTealiumConfig.consentPolicy = .ccpa
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.consentManager)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testConsentManagerNilWhenPolicyNotSet() {
        let expect = expectation(description: "Consent Manager Module nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.consentManager)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLoggerNotNil() {
        let expect = expectation(description: "Logger not nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.logger)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testVisitorServiceNotNil() {
        let expect = expectation(description: "Visitor Service Manager not nil")
        defaultTealiumConfig.collectors = [Collectors.VisitorService]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.visitorService)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testVisitorServiceNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Visitor Service Manager nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.visitorService)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLifecycleNotNil() {
        let expect = expectation(description: "Lifecycle not nil")
        defaultTealiumConfig.collectors = [Collectors.Lifecycle]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLifecycleNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Lifecycle nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.lifecycle)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    #if os(iOS)
    func testLocationNotNil() {
        let expect = expectation(description: "Location not nil")
        defaultTealiumConfig.collectors = [Collectors.Location]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.location)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testLocationNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Location nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.location)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testAutotrackingNotNil() {
        let expect = expectation(description: "Autotracking not nil")
        defaultTealiumConfig.collectors = [Collectors.AutoTracking]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.autotracking)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testAutotrackingNilWhenNotSetAsCollector() {
        let expect = expectation(description: "Autotracking nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.autotracking)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testRemoteCommandsNotNil() {
        let expect = expectation(description: "Remote Commands not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.RemoteCommands]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testRemoteCommandsNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Remote Commands nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.remoteCommands)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testTagManagementNotNil() {
        let expect = expectation(description: "Tag Management not nil")
        defaultTealiumConfig.dispatchers = [Dispatchers.TagManagement]
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNotNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testTagManagementNilWhenNotSetAsDispatcher() {
        let expect = expectation(description: "Tag Management nil")
        tealium = Tealium(config: defaultTealiumConfig) { _ in
            XCTAssertNil(self.tealium.tagManagement)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }
    #endif

}
