//
//  TealiumVisitorProfileManagerTests.swift
//  TealiumSwiftTests
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class TealiumVisitorProfileManagerTests: XCTestCase {

    var visitorProfileManager: TealiumVisitorProfileManager?
    var mockDiskStorage: MockTealiumDiskStorage!
    let tealHelper = TestTealiumHelper()
    var expectations = [XCTestExpectation]()
    let maxRuns = 10 // max runs for each test
    let waiter = XCTWaiter()
    var currentTest: String = ""

    override func setUp() {
        expectations = [XCTestExpectation]()
        visitorProfileManager = nil
        mockDiskStorage = MockTealiumDiskStorage()
        visitorProfileManager = TealiumVisitorProfileManager(config: TestTealiumHelper().getConfig(), delegates: nil, diskStorage: mockDiskStorage)
        visitorProfileManager?.visitorProfileRetriever = TealiumVisitorProfileRetriever(config: TestTealiumHelper().getConfig(), visitorId: "abc123", urlSession: MockURLSession())
    }

    override func tearDown() {
        visitorProfileManager = nil
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

    func testInitialVisitorProfileSettingsFromConfig() {
        let config = tealHelper.getConfig()
        config.visitorServiceRefreshInterval = 10
        let interval = config.visitorServiceRefreshInterval!
        XCTAssertEqual(interval, 10)

    }

    func testRequestVisitorProfile() {
        let expectation = self.expectation(description: "testDelegateDidUpdateViaRequestVisitorProfile")
        currentTest = "testDelegateDidUpdateViaRequestVisitorProfile"
        expectations.append(expectation)
        visitorProfileManager?.addVisitorServiceDelegate(self)
        visitorProfileManager?.visitorId = "test"
        visitorProfileManager?.requestVisitorProfile()
        waiter.wait(for: expectations, timeout: 5.0)
    }

    func testBlockState() {
        visitorProfileManager?.blockState()
        XCTAssertEqual(1, visitorProfileManager?.currentState.value)
    }

    func testReleaseState() {
        visitorProfileManager?.releaseState()
        XCTAssertEqual(0, visitorProfileManager?.currentState.value)
    }

    func testLifetimeEventCountHasBeenUpdated() {
        visitorProfileManager?.lifetimeEvents = 4.0
        let result = visitorProfileManager?.lifetimeEventCountHasBeenUpdated(5.0)
        XCTAssertTrue(result!)
    }

    func testLifetimeEventCountNotUpdated() {
        visitorProfileManager?.lifetimeEvents = 4.0
        let result = visitorProfileManager?.lifetimeEventCountHasBeenUpdated(4.0)
        XCTAssertFalse(result!)
    }

    func testCheckIfVisitorProfileIsEmpty() {
        let visitorAllNil = loadStub(from: "visitor-all-nil", with: "json")
        let nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitorAllNil)
        let result = nilAttributes.isEmpty
        XCTAssertTrue(result)
    }

    func testCheckIfVisitorProfileIsNotEmpty() {
        let visitor = loadStub(from: "visitor", with: "json")
        var nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitor)
        var result = nilAttributes.isEmpty
        XCTAssertFalse(result)

        let visitorWithNils = loadStub(from: "visitor-nils", with: "json")
        nilAttributes = try! JSONDecoder().decode(TealiumVisitorProfile.self, from: visitorWithNils)
        result = nilAttributes.isEmpty
        XCTAssertFalse(result)
    }

}

extension TealiumVisitorProfileManagerTests: TealiumVisitorServiceDelegate {

    func profileDidUpdate(profile: TealiumVisitorProfile?) {
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
        self.getExpectation(forDescription: "testDelegateDidUpdateViaRequestVisitorProfile")?.fulfill()
        //        }
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) {
        self.getExpectation(forDescription: "testPollForVisitorProfile")?.fulfill()
        //        }
        visitorProfileManager?.timer?.suspend()
    }

}
