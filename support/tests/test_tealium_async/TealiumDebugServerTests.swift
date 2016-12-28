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
    
    func testStartServer() {
        
        
    
    }
    
    func testSetupSockets() {
        
    }
    
    func testServeTrack() {
        
        let debugServer = TealiumDebugServer()
        debugServer.debugQueue = [["foo": "bar"], ["gamma": "delta"], ["kappa": ["omega": "omnicron"]]]
        debugServer.serveTrack()
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when) {
            XCTAssertTrue(debugServer.debugQueue.isEmpty)
        }
        
    }
    
    func testAddToDebugQueue () {
    
        let testQueue = [["foo": "bar"], ["gamma": "delta"], ["kappa": ["omega": "omnicron"]]]
        
        let debugServer = TealiumDebugServer()
        
        debugServer.addToDebugQueue(["foo" : "bar"])
        debugServer.addToDebugQueue(["gamma": "delta"])
        debugServer.addToDebugQueue(["kappa": ["omega": "omnicron"]])
        
        for i in 0..<debugServer.debugQueue.count {
            
            XCTAssertTrue(debugServer.debugQueue[i] == testQueue[i], "test queue \(testQueue[i])was not added to debugQueue as expected \(debugServer.debugQueue[i]).")
        }
        
        
    }
    
    
    
    func testStop() {
    
    }
    
    func testEncodeDictToJson() {
        
        let expectedString = "{\"type\":\"foo\",\"info\":\"\",\"data\":{\"dev\":\"bar\"}}"

        
        let dictionary = ["type": "foo",
                          "info": "",
                          "data" : ["dev" : "bar"]] as [String : Any]
    
        let debugServer = TealiumDebugServer()
      
        do {
            let testString  = try debugServer.encodeDictToJson(dict: dictionary)
            
            XCTAssertTrue(expectedString == testString, "test string \(testString) is not encoded properly: expected \(expectedString).")
    
        } catch {
    
            XCTFail("Error when trying to encode")

        }
    
    }
}
