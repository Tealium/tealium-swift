//
//  TealiumConstantsTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/25/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumConstantsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testConstantsStrings(){
        
        XCTAssertTrue(TealiumTrackType.view.description() == "view")
        XCTAssertTrue(TealiumTrackType.activity.description() == "activity")
        XCTAssertTrue(TealiumTrackType.interaction.description() == "interaction")
        XCTAssertTrue(TealiumTrackType.derived.description() == "derived")
        XCTAssertTrue(TealiumTrackType.conversion.description() == "conversion")
    }


}
