//
//  VisitorProfileTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
@testable import TealiumVisitorService
import XCTest

class VisitorProfileTests: XCTestCase {

    let visitorJSON = TestTealiumHelper.loadStub(from: "visitor", VisitorProfileTests.self)
    let visitorEmpties = TestTealiumHelper.loadStub(from: "visitor-empties", VisitorProfileTests.self)
    let visitorNils = TestTealiumHelper.loadStub(from: "visitor-nils", VisitorProfileTests.self)
    let visitorAllNil = TestTealiumHelper.loadStub(from: "visitor-all-nil", VisitorProfileTests.self)
    let visitorPropertiesWithNull = TestTealiumHelper.loadStub(from: "visitor-properties-with-null", VisitorProfileTests.self)
    let decoder = JSONDecoder()
    
    private func decode(_ data: Data) -> TealiumVisitorProfile {
        try! decoder.decode(TealiumVisitorProfile.self, from: data)
    }

    func testCodableObjectReturnsExpectedData() {
        let visitor = decode(visitorJSON)
        guard let currentVisit = visitor.currentVisit else {
            XCTFail("CurrentVisit does not conform to protocol")
            return
        }

        XCTAssertNotNil(visitor.audiences?["services-christina_advance_110"])
        XCTAssertNil(visitor.audiences?["blah"])
        XCTAssertEqual(visitor.badges?["8535"], true)
        XCTAssertEqual(visitor.badges?["6301"], true)
        XCTAssertNil(visitor.badges?["9999"])
        XCTAssertNotNil(visitor.tallies?["8481"])
        XCTAssertNil(visitor.tallies?["9999"])
        guard let tally = visitor.tallies?["8481"] else {
            XCTFail("Tally 8481 should exist")
            return
        }
        XCTAssertNotNil(tally["category 5"])
        XCTAssertNil(tally["category 99"])
        XCTAssertNotNil(currentVisit.strings?["44"])
        XCTAssertNotNil(currentVisit.strings?["44"])
        XCTAssertNotNil(currentVisit.strings?["44"])
        XCTAssertNil(currentVisit.strings?["999"])
        XCTAssertNotNil(currentVisit.dates?["11"])
    }

    func testCodableWithNils() {
        let visitor = decode(visitorNils)
        XCTAssertNil(visitor.tallies)
        XCTAssertNil(visitor.strings)
        XCTAssertNotNil(visitor.dates)
        XCTAssertNotNil(visitor.arraysOfStrings)
        XCTAssertNil(visitor.currentVisit)
    }

    func testCodableWithoutCertainKeys() {
        let visitor = decode(visitorEmpties)
        guard let currentVisit = visitor.currentVisit else {
            XCTFail("CurrentVisit does not conform to protocol")
            return
        }
        XCTAssertNil(visitor.audiences)
        XCTAssertNil(visitor.strings)
        XCTAssertNotNil(visitor.dates)
        XCTAssertNotNil(visitor.tallies)
        XCTAssertNil(currentVisit.setsOfStrings)
        XCTAssertNotNil(currentVisit.arraysOfBooleans)
    }

    func testAudienceSubscriptById() {
        let visitor = decode(visitorJSON)
        XCTAssertNotNil(visitor.audiences?["services-christina_advance_110"])
        XCTAssertNotNil(visitor.audiences?["services-christina_advance_103"])
    }

    func testOtherAttributesById() {
        let visitor = decode(visitorJSON)
        guard let currentVisit = visitor.currentVisit else {
            XCTFail("CurrentVisit does not conform to protocol")
            return
        }
        XCTAssertEqual(visitor.badges?["8535"], true)
        XCTAssertEqual(visitor.dates?["23"], 1_557_421_336_000)
        XCTAssertEqual(visitor.booleans?["27"], true)
        XCTAssertEqual(currentVisit.arraysOfBooleans?["8479"] , [true, false, true, false, true, false, true, false])
        XCTAssertEqual(visitor.numbers?["25"], 27.983_333_333_333_334)
        XCTAssertEqual(visitor.arraysOfNumbers?["8487"], [3.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
        let tally = visitor.tallies?["8481"]
        XCTAssertNotNil(tally)
        XCTAssertEqual(tally?["category 3"], 1.0)
        XCTAssertEqual(visitor.strings?["8480"], "category 5")
        XCTAssertEqual(visitor.arraysOfStrings?["8483"],
                       ["category 4", "category 5", "category 5", "category 5", "category 5", "category 5", "category 5",
                        "category 5", "category 5", "category 5", "category 5", "category 5", "category 5"])
        XCTAssertEqual(currentVisit.setsOfStrings?["50"], ["Mac OS X"])
    }

    func testAudienceSubscriptByIdNil() {
        let visitor = decode(visitorNils)
        XCTAssertNil(visitor.audiences?["services-christina_advance_112"])
    }

    func testOtherAttributesByIdNil() {
        let visitor = decode(visitorNils)
        XCTAssertNil(visitor.currentVisit)
        XCTAssertNil(visitor.tallies?["8481"])
        XCTAssertNil(visitor.strings?["8480"])
    }

    func testBadgesSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.badges?["9999"])
    }

    func testBadgesSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertNotNil(visitor.badges?["8535"])
    }

    func testBadgesSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.badges?["9999"])
    }

    func testBooleansSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.booleans?["9999"] )
    }

    func testBooleansSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertNotNil(visitor.booleans?["27"])
        XCTAssertEqual(visitor.booleans?["27"], true)
    }

    func testBooleansSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.booleans?["9999"])
    }

    func testArrayOfBooleansSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.currentVisit?.arraysOfBooleans?["9999"])
    }

    func testArrayOfBooleansSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.currentVisit?.arraysOfBooleans?["8479"], [true, false, true, false, true, false, true, false])
    }

    func testArrayOfBooleansSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.currentVisit?.arraysOfBooleans?["9999"])
    }

    func testDatesSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.dates?["9999"])
    }

    func testDatesSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.dates?["5089"], 1_557_777_940_471)
    }

    func testDatesSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.dates?["9999"])
    }

    func testNumbersSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.numbers?["9999"])
    }

    func testNumbersSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.numbers?["22"], 25.0)
    }

    func testNumbersSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.numbers?["9999"])
    }

    func testArrayOfNumbersSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.arraysOfNumbers?["9999"])
    }

    func testArrayOfNumbersSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.arraysOfNumbers?["8487"], [3.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
    }

    func testArrayOfNumbersSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.arraysOfNumbers?["9999"])
    }

    func testTallySubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.tallies?["9999"])
    }

    func testTallySubscriptSuccess() {
        let expected: [String: Float] = ["category 1": 2.0,
                                         "category 2": 1.0,
                                         "category 3": 1.0,
                                         "category 4": 1.0,
                                         "category 5": 12.0]
        let visitor = decode(visitorJSON)
        guard let tally = visitor.tallies?["8481"] else {
            XCTFail("Tally not found")
            return
        }
        XCTAssert(NSDictionary(dictionary: tally).isEqual(to: expected) )
    }

    func testTallySubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.tallies?["9999"])
    }

    func testTallyValueSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        let tally = visitor.tallies?["9999"]
        let tallyValue = tally?["category 4"]
        XCTAssertNil(tallyValue)
    }

    func testTallyValueSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        let tally = visitor.tallies?["8481"]
        let tallyValue = tally?["category 4"]
        XCTAssertEqual(tallyValue, 1.0)
    }

    func testTallyValueSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.tallies?["9999"])
    }

    func testVisitorStringSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.strings?["9999"])
    }

    func testVisitorStringSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.strings?["8480"] , "category 5")
    }

    func testVisitorStringSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.strings?["9999"])
    }

    func testArrayOfStringsSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNil(visitor.arraysOfStrings?["9999"])
    }

    func testArrayOfStringsSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertEqual(visitor.arraysOfStrings?["8483"],
                       ["category 4", "category 5", "category 5", "category 5", "category 5", "category 5", "category 5",
                        "category 5", "category 5", "category 5", "category 5", "category 5", "category 5"])
    }

    func testArrayOfStringsSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.arraysOfStrings)
        XCTAssertNil(visitor.arraysOfStrings?["9999"])
    }

    func testSetOfStringsSubscriptNoResult() {
        let visitor = decode(visitorJSON)
        XCTAssertNotNil(visitor.currentVisit)
        XCTAssertNil(visitor.currentVisit?.setsOfStrings?["27"])
    }

    func testSetOfStringsSubscriptSuccess() {
        let visitor = decode(visitorJSON)
        XCTAssertNotNil(visitor.currentVisit)
        let shouldExistInProfile = visitor.currentVisit?.setsOfStrings?["50"]
        XCTAssertNotNil(shouldExistInProfile)
        XCTAssertEqual(shouldExistInProfile, ["Mac OS X"])
    }

    func testSetOfStringsSubscriptNil() {
        let visitor = decode(visitorAllNil)
        XCTAssertNil(visitor.currentVisit)
        XCTAssertNil(visitor.currentVisit?.setsOfStrings?["27"])
    }

    func testAttributeMapping() {
        let visitor = decode(visitorJSON)
        let tally = visitor.tallies?["8481"]
        XCTAssertNotNil(tally)
        XCTAssertEqual(tally?["category 3"], 1.0)

        let arraysOfBooleans = visitor.currentVisit?.arraysOfBooleans?["8479"]
        let countOfPositiveBools = arraysOfBooleans?.filter { $0 == true }.count
        XCTAssertEqual(countOfPositiveBools, 4)
        
        let arraysOfNumbers = visitor.arraysOfNumbers?["8487"]
        let countOfNumber1 = arraysOfNumbers?.filter { $0 == 1.0 }.count
        XCTAssertEqual(countOfNumber1, 11)

        let arraysOfStrings = visitor.arraysOfStrings?["8483"]
        let countOfCategory4 = arraysOfStrings?.filter { $0.lowercased().contains("category 4")}.count
        XCTAssertEqual(countOfCategory4, 1)
    }

    func testNullStringsInVisitorProfile() {
        let visitor = decode(visitorPropertiesWithNull)
        XCTAssertNotNil(visitor.strings)
        XCTAssertEqual(visitor.strings?["8480"], "category 5")
    }

    func testNullStringsInCurrentVisit() {
        let visitor = decode(visitorPropertiesWithNull)
        XCTAssertNotNil(visitor.currentVisit?.strings)
        XCTAssertEqual(visitor.currentVisit?.strings?["44"], "Chrome")
    }
}
