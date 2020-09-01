//
//  AttributionModuleTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

//  Application Test do to UIKit not being available to Unit Test Bundle

@testable import TealiumAttribution
@testable import TealiumCore
import XCTest

class AttributionModuleTests: XCTestCase {

    var module: AttributionModule?
    var config: TealiumConfig!
    var expectation: XCTestExpectation?
    var payload: [String: Any]?
    var attributionData = MockAttributionData()

    override func setUp() {
        config = TestTealiumHelper().getConfig()
        module = AttributionModule(config: config, delegate: nil, diskStorage: AttributionMockDiskStorage(), attributionData: attributionData)
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
