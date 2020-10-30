//
//  AttributionModuleTests.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

class AttributionModuleTests: XCTestCase {

    var module: AttributionModule?
    var context: TealiumContext!
    var expectation: XCTestExpectation?
    var payload: [String: Any]?
    var attributionData = MockAttributionData()

    override func setUp() {
        let config = TestTealiumHelper().getConfig()
        let context = TestTealiumHelper.context(with: config)
        module = AttributionModule(context: context, delegate: nil, diskStorage: AttributionMockDiskStorage(), attributionData: attributionData)
    }

    func testGetAttributionData() {
        let allAttrData = self.module?.data
        XCTAssertNotNil(allAttrData?[AttributionKey.clickedDate])
        XCTAssertNotNil(allAttrData?[AttributionKey.idfa])
        XCTAssertNotNil(allAttrData?[AttributionKey.idfv])
        XCTAssertNotNil(allAttrData?[AttributionKey.orgName])
        XCTAssertNotNil(allAttrData?[AttributionKey.campaignName])
        XCTAssertNotNil(allAttrData?[AttributionKey.creativeSetName])

    }

}
