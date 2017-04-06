//
//  TealiumTagManagementTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 12/16/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest


/// Can only test class level functions due to limitation of XCTest with WebViews
class TealiumTagManagementUtilsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        //
    }
    
    override func tearDown() {
        //
        super.tearDown()
    }
    
    func testGetLegacyTypeView() {

        let eventType = "tealium_event_type"
        let viewValue = "view"
        let viewDictionary = [eventType:viewValue]
        let viewResult = TealiumTagManagementUtils.getLegacyType(fromData: viewDictionary)
        
        XCTAssertTrue(viewResult == viewValue)
        
    }
    
    func testGetLegacyTypeEvent() {
        
        let eventType = "tealium_event_type"
        let anyValue = "any"
        let eventDictionary = [eventType:anyValue]
        let eventResult = TealiumTagManagementUtils.getLegacyType(fromData: eventDictionary)
        
        XCTAssertTrue(eventResult == "link")
        
    }
    
    func testJSONEncode(){
        
        let dict : [String:String] = ["xyz":"2",
                                      "abc":"123",
                                      "1":"end"]
        let data =
            TealiumTagManagementUtils
                .jsonEncode(sanitizedDictionary:dict)
        
        let dataString = "\(data!)"
        
        XCTAssertTrue(dataString == "{\"abc\":\"123\",\"xyz\":\"2\",\"1\":\"end\"}", "Unexpected dataString: \(dataString)")
    }
    
    func testSanitized() {
        
        let rawDictionary = ["string" : "string",
                             "int" : 5,
                             "float": 1.2,
                             "bool" : true,
                             "arrayOfStrings" : ["a", "b", "c"],
                             "arrayOfVariousNumbers": [1, 2.2, 3.0045],
                             "arrayOfBools" : [true, false, true],
                             "arrayOfMixedElements": [1, "two", 3.00]] as [String : Any]
        
        let sanitized = TealiumTagManagementUtils.sanitized(dictionary: rawDictionary)
        
        print("Sanitized Dictionary: \(sanitized as AnyObject)")
        
        // TODO: Test data recieved by UDH
        
            // Sample output
//        Sanitized Dictionary: {
//            arrayOfBools = "[true, false, true]";
//            arrayOfMixedElements = "[1, \"two\", 3.0]";
//            arrayOfStrings = "[\"a\", \"b\", \"c\"]";
//            arrayOfVariousNumbers = "[1.0, 2.2000000000000002, 3.0045000000000002]";
//            bool = true;
//            float = "1.2";
//            int = 5;
//            string = string;
//        }
    }
}
