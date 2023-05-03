//
//  TealiumVisitorServiceManagerTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class VisitorServiceManagerTests: XCTestCase {

    var visitorServiceManager: VisitorServiceManager?
    var mockDiskStorage: MockTealiumDiskStorage!
    let tealHelper = TestTealiumHelper()
    var expectations = [XCTestExpectation]()
    let maxRuns = 10 // max runs for each test
    let waiter = XCTWaiter()
    var currentTest: String = ""
    let visitorId = "abc123"

    override func setUp() {
        expectations = [XCTestExpectation]()
        visitorServiceManager = nil
        mockDiskStorage = MockTealiumDiskStorage()
        let config = TealiumConfig(account: "test", profile: "test", environment: "prod")
        visitorServiceManager = VisitorServiceManager(config: config, delegate: self, diskStorage: mockDiskStorage)
        visitorServiceManager?.visitorServiceRetriever = VisitorServiceRetriever(config: TestTealiumHelper().getConfig(), urlSession: MockURLSession())
    }

    override func tearDown() {
        visitorServiceManager = nil
    }

    func testInitialVisitorProfileSettingsFromConfig() {
        let config = tealHelper.getConfig()
        config.visitorServiceRefresh = .every(10, .minutes)
        let refresh = config.visitorServiceRefresh!
        XCTAssertEqual(refresh.interval, 600)
    }

    func testRequestVisitorProfile() {
        let expectation = self.expectation(description: "testDelegateDidUpdateViaRequestVisitorProfile")
        currentTest = "testDelegateDidUpdateViaRequestVisitorProfile"
        expectations.append(expectation)
        visitorServiceManager?.delegate = self
        visitorServiceManager?.requestVisitorProfile()
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testBlockState() {
        visitorServiceManager?.blockState()
        XCTAssertEqual(visitorServiceManager?.currentState, VisitorServiceStatus.blocked)
    }

    func testReleaseState() {
        visitorServiceManager?.releaseState()
        XCTAssertEqual(visitorServiceManager?.currentState, VisitorServiceStatus.ready)
    }

    func testLifetimeEventCountHasBeenUpdated() {
        let visitor = TestTealiumHelper.loadStub(from: "visitor", type(of: self))
        var profile = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitor)
        profile.lifetimeEventCount = 4.0
        visitorServiceManager?.diskStorage.save(profile, completion: nil)
        let result = visitorServiceManager?.lifetimeEventCountHasBeenUpdated(5.0)
        XCTAssertTrue(result!)
    }

    func testLifetimeEventCountNotUpdated() {
        let visitor = TestTealiumHelper.loadStub(from: "visitor", type(of: self))
        var profile = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitor)
        profile.lifetimeEventCount = 4.0
        visitorServiceManager?.diskStorage.save(profile, completion: nil)
        let result = self.visitorServiceManager?.lifetimeEventCountHasBeenUpdated(4.0)
        XCTAssertFalse(result!)
    }

    func testCheckIfVisitorProfileIsEmpty() {
        let visitorAllNil = TestTealiumHelper.loadStub(from: "visitor-all-nil", type(of: self))
        let nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitorAllNil)
        let result = nilAttributes.isEmpty
        XCTAssertTrue(result)
    }

    func testCheckIfVisitorProfileIsNotEmpty() {
        let visitor = TestTealiumHelper.loadStub(from: "visitor", type(of: self))
        var nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitor)
        var result = nilAttributes.isEmpty
        XCTAssertFalse(result)

        let visitorWithNils = TestTealiumHelper.loadStub(from: "visitor-nils", type(of: self))
        nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitorWithNils)
        result = nilAttributes.isEmpty
        XCTAssertFalse(result)
    }

    func testLastFetchGetsResetOnVisitorChange() {
        let expectation = expectation(description: "fetch completed")
        visitorServiceManager?.currentVisitorId = "oldId"
        visitorServiceManager?.fetchProfile(visitorId: "oldId", completion: { _, _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 3.0)
        XCTAssertNotNil(visitorServiceManager?.lastFetch)
        visitorServiceManager?.currentVisitorId = "newId"
        XCTAssertNil(visitorServiceManager?.lastFetch)
    }
}

extension VisitorServiceManagerTests: VisitorServiceDelegate {

    func didUpdate(visitorProfile: TealiumVisitorProfile) {
        for expectation in expectations {
            expectation.fulfill()
        }
        visitorServiceManager?.timer?.suspend()
    }

}
