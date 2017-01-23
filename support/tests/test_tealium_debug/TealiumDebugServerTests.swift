//
//  TealiumDebugServerTests.swift
//  tealium-swift
//
//  Created by Merritt Tidwell on 12/21/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest


class TealiumDebugServerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testServeTrack() {
        
        let debugServer = TealiumDebugServer()
        debugServer.debugQueue = [["foo": "bar"], ["gamma": "delta"], ["kappa": ["omega": "omnicron"]]]
        debugServer.sendQueue()
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            XCTAssertTrue(debugServer.debugQueue.isEmpty)
        }
        
    }
    
    func testAddToDebugQueue () {
    
        let testQueue = [["foo": "bar"], ["gamma": "delta"], ["kappa": ["omega": "omnicron"]]]
        
        let debugServer = TealiumDebugServer()
        
        debugServer.add(["foo" : "bar"])
        debugServer.add(["gamma": "delta"])
        debugServer.add(["kappa": ["omega": "omnicron"]])
        
        for i in 0..<debugServer.debugQueue.count {
            
            XCTAssertTrue(debugServer.debugQueue[i] == testQueue[i], "test queue \(testQueue[i])was not added to debugQueue as expected \(debugServer.debugQueue[i]).")
        }
        
    }
    
    func testQueueMaxLimit () {
      
        let debugServer = TealiumDebugServer()
        debugServer.queueMax = 50
        
        for i in 1..<53 {
            debugServer.add(["\(i)": "\(i)"])
        }
      
        XCTAssertTrue(debugServer.debugQueue.count == debugServer.queueMax, " expected count of  \(debugServer.queueMax) does not match queue count:  \(debugServer.debugQueue.count)")

        XCTAssertFalse(debugServer.debugQueue.contains { $0 == ["1":"1"] }, "queue is not compliant with FIFO \(debugServer.debugQueue.description)")
        
        XCTAssertTrue(debugServer.debugQueue[49] == ["52":"52"], "Last item in debugQueue \(debugServer.debugQueue[49]) is not expected")
        
        XCTAssertTrue(debugServer.debugQueue[0] == ["3":"3"], "First item in debugQueue \(debugServer.debugQueue[0]) is not expected")

    }
    
    
    func testEncodeDictToJsonWithAcceptableDictionary() {
        
        let expectedString = "{\"info\":\"\",\"data\":{\"dev\":\"bar\"},\"int\":15,\"type\":\"foo\",\"float\":10,\"bool\":true}"
        
        let dictionary : [String:Any] = ["type": "foo",
                                         "info": "",
                                         "data" : ["dev" : "bar"],
                                         "bool": true,
                                         "int" : 15,
                                         "float" : 10.0
                                        ]
        
        let testString  = TealiumDebugServer.encodeToJsonString(dict: dictionary)
        
        XCTAssertTrue(expectedString == testString, "test string \(testString) is not encoded properly: expected \(expectedString).")

    
    }
    
    func testEncodeDictToJsonWithUnacceptableDictionary() {
        
        // Functions aren't JSON encodable
        let function = {() in
            print("empty test function")
        }
        
        let dictionary : [String:Any] = ["type": "foo",
                                         "function":function
        ]
        
        let testString  = TealiumDebugServer.encodeToJsonString(dict: dictionary)
        
        XCTAssertTrue(testString == nil, "Returned json string should have been nil")
        
    }
    
    func testStringFilter() {
        
        let function = {() in
            print("empty test function")
        }
        
        let dictionary : [String:Any] = ["type": true,
                                         "info": 15,
                                         "data":["dev":10.0],
                                         "function": function
        ]
        
        let testDict  = TealiumDebugServer.stringOnly(dictionary: dictionary)

        let expectedDictionary : [String:Any] = ["type":"true",
                                                 "info":"15",
                                                 "data":"[\"dev\": \"10.0\"]", // Why is a space appended here?
                                                 "function":"(Function)"
        ]
        XCTAssertTrue(expectedDictionary == testDict, "Mismatch between expected dict: \(expectedDictionary) and returned: \(testDict)")

    }
    
    func testSetQueueMax () {
        
        let debugServer = TealiumDebugServer()

        debugServer.queueMax = -1
        XCTAssertTrue(debugServer.queueMax == TealiumDebugKey.defaultQueueMax, "Debug fails to set to expected value\(TealiumDebugKey.defaultQueueMax) and instead is \(debugServer.queueMax)")
        
        debugServer.queueMax = 1020
        XCTAssertTrue(debugServer.queueMax == TealiumDebugKey.overrideQueueSizeLimit, "Debug fails to set to expected value\(TealiumDebugKey.overrideQueueSizeLimit) and instead is \(debugServer.queueMax)")
        
        debugServer.queueMax = 50
        XCTAssertTrue(debugServer.queueMax == 50, "Debug fails to set to expected value\(50) and instead is \(debugServer.queueMax)")

    }
    
}
