//
//  TealiumDataManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

/**
    Allows dictionary to check if it contains keys and values from a smaller library
 
    - Paramaters:
        - smallerDictionary: A [String:AnyObject] dictionary
    - Returns: Boolean answer
 */
extension Dictionary where Key:StringLiteralConvertible, Value:AnyObject{
    
    func contains(smallerDictionary:[String:AnyObject])-> Bool {
        
        // Should use generics here
        
        for (key, value) in smallerDictionary {
            guard let largeValue = self[(key as? Key)!] else {
                return false
            }
            if largeValue as? String != value as? String {
                return false
            }
            if let largeValue = largeValue as? [String] {
                if let smallValue = value as? [String] {
                    if largeValue != smallValue {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
}

class TealiumDataManagerTests: XCTestCase {

    let account = "account"
    let profile = "profile"
    let env = "environment"
    var config : TealiumConfig!
    var dataManager : TealiumDataManager!
    
    override func setUp() {
        
        super.setUp()
        config = TealiumConfig(account: account, profile: profile, environment: env)

        guard let dataManager = TealiumDataManager(account: account, profile: profile, environment: env) else {
            print("Failed to launch the data manager")
            return
        }
        self.dataManager = dataManager
    }
    
    override func tearDown() {
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testInit() {
        
        // The compiler works...yay
        XCTAssertTrue(dataManager != nil)
        
    }
    
    func testVolatileData(){
        
        // TODO: test arrays and other value types
        
        let testData = [
            "a":"1",
            "b":"2"
        ]
        
        
        dataManager.addVolatileData(testData)
        let volatileData = dataManager.getVolatileData()
        
        print("VolatileData: \(volatileData)")
        
        XCTAssertTrue(volatileData.contains(testData), "VolatileData: \(volatileData)")

        dataManager.deleteVolatileData(["a","b"])
        
        let volatileDataPostDelete = dataManager.getVolatileData()
        
        XCTAssertFalse(volatileDataPostDelete.contains(testData), "VolatileData: \(volatileDataPostDelete)")
    }
    
    // This test passes individually, not always as part of full test run.
    func testPersistentData() {
        
        // TODO: test arrays and other value types

        let testData = [
            "a":"1",
            "b":"2"
        ]
        
        dataManager.addPersistentData(testData)
        
        guard let persistentData = dataManager.getPersistentData() else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(persistentData.contains(testData), "PersistentData: \(persistentData)")
        
        dataManager.deletePersistentData(["a","b"])
        
        guard let persistentDataPostDelete = dataManager.getPersistentData() else {
            XCTFail()
            return
        }
        
        XCTAssertFalse(persistentDataPostDelete.contains(testData), "PersistentData: \(persistentDataPostDelete)")
        
    }
    
    func testNewPersistentData() {
        
        var expected = [String:AnyObject]()
        expected[tealiumKey_library_name] = "swift"
        expected[tealiumKey_library_version] = "1.0.0"
        expected[tealiumKey_account] = account
        expected[tealiumKey_profile] = profile
        expected[tealiumKey_environment] = env
        
        // Not testing tealium_visitor_id or tealium_vid
        
        let new = dataManager.newPersistentData()
        
        XCTAssertTrue(new.contains(expected))
        
    }
    
    func testGetRandom(){
        
        let volatileData = dataManager.getVolatileData()
        guard let random = volatileData[tealiumKey_random] as? String else {
            XCTFail()
            return
        }
        
        guard let otherData = TealiumDataManager(account: self.account, profile: self.profile, environment: self.env) else {
            XCTFail("DataManager could not be initialized.")
            return
        }
        
        let otherVolatileData = otherData.getVolatileData()
        guard let otherRandom = otherVolatileData[tealiumKey_random] as? String else {
            XCTFail()
            return
        }
        
        let regex = try! NSRegularExpression(pattern: "^[0-9]{16}$", options: [])
        
        XCTAssertNotNil(random, "tealium_random : \(random)")
        
        XCTAssertNotEqual(random, otherRandom)
        
        let matches = regex.numberOfMatchesInString(random, options: [], range: NSRange(location: 0, length: random.characters.count))
        let matches2 = regex.numberOfMatchesInString(otherRandom, options: [], range: NSRange(location: 0, length: otherRandom.characters.count))
        
        XCTAssertTrue(matches == 1)
        XCTAssertTrue(matches2 == 1)
    }
    
    func testGetRandomWithIterator(){
        var randomNumbers = [String]()
        let regex = try! NSRegularExpression(pattern: "^[0-9]{16}$", options: [])
        
        for _ in 1...100 {
            let random = dataManager.getRandom()
            if randomNumbers.contains(random) == true {
                XCTFail("Duplicate random number")
            } else {
                let matches = regex.numberOfMatchesInString(random, options: [], range: NSRange(location: 0, length: random.characters.count))
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
        
        let sessionId = dataManager.resetSessionId()
        sleep(1)
        let sessionId2 = dataManager.resetSessionId()
        
        XCTAssertNotEqual(sessionId, sessionId2)
        
    }


}
