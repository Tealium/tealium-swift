//
//  VisitorProfilePerformanceTests.swift
//  TealiumVisitorServiceTests-iOS
//
//  Created by Christina S on 4/14/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumVisitorService
import XCTest

class VisitorProfilePerformanceTests: XCTestCase {

    var json: Data!
    let decoder = JSONDecoder()

    override func setUpWithError() throws {
        json = loadStub(from: "big-visitor", with: "json")
    }

    override func tearDownWithError() throws { }

    func testPerformanceVisitorProfileWithHelperMethods() throws {
        self.measure {
            let profile = try! decoder.decode(TealiumVisitorProfile.self, from: json)
            XCTAssertEqual(profile.audiences?.count, 188)
            XCTAssertEqual(profile.badges?.count, 256)
            XCTAssertEqual(profile.dates?.count, 448)
            XCTAssertEqual(profile.booleans?.count, 176)
            XCTAssertEqual(profile.arraysOfBooleans?.count, 80)
            XCTAssertEqual(profile.numbers?.count, 464)
            XCTAssertEqual(profile.arraysOfNumbers?.count, 48)
            XCTAssertEqual(profile.tallies?.count, 6)
            XCTAssertEqual(profile.strings?.count, 288)
            XCTAssertEqual(profile.arraysOfStrings?.count, 50)
            XCTAssertEqual(profile.setsOfStrings?.count, 100)
            XCTAssertEqual(profile.currentVisit?.dates?.count, 448)
            XCTAssertEqual(profile.currentVisit?.booleans?.count, 176)
            XCTAssertEqual(profile.currentVisit?.arraysOfBooleans?.count, 80)
            XCTAssertEqual(profile.currentVisit?.numbers?.count, 464)
            XCTAssertEqual(profile.currentVisit?.arraysOfNumbers?.count, 48)
            XCTAssertEqual(profile.currentVisit?.tallies?.count, 6)
            XCTAssertEqual(profile.currentVisit?.strings?.count, 288)
            XCTAssertEqual(profile.currentVisit?.arraysOfStrings?.count, 50)
            XCTAssertEqual(profile.currentVisit?.setsOfStrings?.count, 100)
        }
    }

}
