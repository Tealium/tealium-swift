//
//  TealiumVolatileDataTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 11/17/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumVolatileDataTests: XCTestCase {
    
    var volatileData : TealiumVolatileData?
    
    override func setUp() {
        super.setUp()
        
        volatileData = TealiumVolatileData()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        volatileData = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetRandomWithIterator(){
        
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up unexpectedly.")
            return
        }
        
        var randomNumbers = [String]()
        let regex = try! NSRegularExpression(pattern: "^[0-9]{16}$", options: [])
        
        for _ in 1...100 {
            let random = volatileData.getRandom()
            if randomNumbers.contains(random) == true {
                XCTFail("Duplicate random number")
            } else {
                let matches = regex.numberOfMatches(in: random, options: [], range: NSRange(location: 0, length: random.characters.count))
                print("matches here is : \(matches)")
                if (matches != 1){
                    print ("random number is :::: \(random)")
                    XCTFail("Random number is not a 16 digits long")
                }
                randomNumbers.append(random)
            }
            
        }
        
    }
    
    func testResetSessionId() {
        
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up unexpectedly.")
            return
        }
        
        let sessionId = volatileData.newSessionId()
        sleep(1)
        let sessionId2 = volatileData.newSessionId()
        
        XCTAssertNotEqual(sessionId, sessionId2)
        
    }
    
    func testVolatileData(){
        
        // TODO: test arrays and other value types
        
        let testData = [
            "a":"1",
            "b":"2"
        ]
        
        guard let volatileData = self.volatileData else {
            XCTFail("TealiumVolatileData did not spin up unexpectedly.")
            return
        }
        
        volatileData.add(data: testData as [String : AnyObject])
        
        let data = volatileData.getData()
        
        XCTAssertTrue(data.contains(smallerDictionary: testData as [String : AnyObject]), "VolatileData: \(volatileData)")
        
        volatileData.deleteData(forKeys:["a","b"])
        
        let volatileDataPostDelete = volatileData.getData()
        
        XCTAssertFalse(volatileDataPostDelete.contains(smallerDictionary: testData as [String : AnyObject]), "VolatileData: \(volatileDataPostDelete)")
    }
    
}
