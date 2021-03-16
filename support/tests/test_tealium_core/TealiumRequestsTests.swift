//
//  TealiumRequestsTests.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class TealiumRequestsTests: XCTestCase {

    func testExtractKeyReturnsNil_lookupNil() {
        let track = TealiumTrackRequest(data: ["tealium_event": "hello_world"])
        let result = track.extractKey(lookup: nil)
        XCTAssertNil(result)
    }

    func testExtractKeyReturnsNil_tealiumEventNotInPayload() {
        let track = TealiumTrackRequest(data: ["hello": "world"])
        let lookup = ["hello": "world"]
        let result = track.extractKey(lookup: lookup)
        XCTAssertNil(result)
    }

    func testExtractKeyReturnsNil_noEventMatch() {
        let track = TealiumTrackRequest(data: ["tealium_event": "hello_world"])
        let lookup = ["hello": "world"]
        let result = track.extractKey(lookup: lookup)
        XCTAssertNil(result)
    }

    func testExtractKeyReturnsExpectedValue() {
        let track = TealiumTrackRequest(data: ["tealium_event": "hello_world"])
        let lookup = ["hello_world": "bye"]
        let result = track.extractKey(lookup: lookup)
        XCTAssertEqual(result, "bye")
    }

    func testExtractLookupValueReturnsNil_keyNotInTrackDictionary() {
        let track = TealiumTrackRequest(data: ["hello": "world"])
        let result = track.extractLookupValue(for: "bye")
        XCTAssertNil(result)
    }

    func testExtractLookupValueReturnsNil_valueIsEmptyArray() {
        let stringArray = [String]()
        let track = TealiumTrackRequest(data: ["hello": stringArray])
        let result = track.extractLookupValue(for: "hello")
        XCTAssertNil(result)
    }

    func testExtractLookupValueReturnsExpected_valueIsStringArray() {
        let track = TealiumTrackRequest(data: ["hello": ["world"]])
        let result = track.extractLookupValue(for: "hello") as? String
        XCTAssertEqual(result, "world")
    }

    func testExtractLookupValueReturnsExpected_valueIsIntArray() {
        let track = TealiumTrackRequest(data: ["hello": [10]])
        let result = track.extractLookupValue(for: "hello") as? Int
        XCTAssertEqual(result, 10)
    }

    func testExtractLookupValueReturnsExpected_valueIsString() {
        let track = TealiumTrackRequest(data: ["hello": "world"])
        let result = track.extractLookupValue(for: "hello") as? String
        XCTAssertEqual(result, "world")
    }

    func testExtractLookupValueReturnsExpected_valueIsInt() {
        let track = TealiumTrackRequest(data: ["hello": 10])
        let result = track.extractLookupValue(for: "hello") as? Int
        XCTAssertEqual(result, 10)
    }
    
    func testTealiumView_ContainsExpectedInfo_NoCustomData() {
        let view = TealiumView("screenName")
        var result = view.trackRequest.trackDictionary
        XCTAssertNotNil(result[TealiumKey.requestUUID] as! String)
        result[TealiumKey.requestUUID] = nil
        XCTAssertTrue(result.equal(to: ["tealium_event": "screenName",
                                        "tealium_event_type": "view",
                                        "screen_title": "screenName"]))
    }
    
    func testTealiumView_ContainsExpectedInfo_WithCustomData() {
        let view = TealiumView("screenName", dataLayer: ["hello": "world"])
        var result = view.trackRequest.trackDictionary
        XCTAssertNotNil(result[TealiumKey.requestUUID] as! String)
        result[TealiumKey.requestUUID] = nil
        XCTAssertTrue(result.equal(to: ["tealium_event": "screenName",
                                        "tealium_event_type": "view",
                                        "screen_title": "screenName",
                                        "hello": "world"]))
    }
    
    func testTealiumEvent_ContainsExpectedInfo_NoCustomData() {
        let event = TealiumEvent("eventName")
        var result = event.trackRequest.trackDictionary
        XCTAssertNotNil(result[TealiumKey.requestUUID] as! String)
        result[TealiumKey.requestUUID] = nil
        XCTAssertTrue(result.equal(to: ["tealium_event": "eventName",
                                        "tealium_event_type": "event"]))
    }
    
    func testTealiumEvent_ContainsExpectedInfo_WithCustomData() {
        let event = TealiumEvent("eventName", dataLayer: ["hello": "world"])
        var result = event.trackRequest.trackDictionary
        XCTAssertNotNil(result[TealiumKey.requestUUID] as! String)
        result[TealiumKey.requestUUID] = nil
        XCTAssertTrue(result.equal(to: ["tealium_event": "eventName",
                                        "tealium_event_type": "event",
                                        "hello": "world"]))
    }


}
