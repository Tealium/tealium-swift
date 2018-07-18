//
//  TealiumDataManagerTests.swift
//  tealium-swift
//
//  Created by Jason Koo on 9/1/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import XCTest

/**
    Allows dictionary to check if it contains keys and values from a smaller library
 
    - Paramaters:
        - smallerDictionary: A [String:AnyObject] dictionary
    - Returns: Boolean answer
 */
extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {

    func contains(smallerDictionary: [String: AnyObject]) -> Bool {

        // Should use generics here

        for (key, value) in smallerDictionary {
            guard let largeValue = self[(key as? Key)!] else {
                print("No entry in source dictionary for key: \(key)")
                return false
            }
            if largeValue as? String != value as? String {
                print("Values as String mismatch for key: \(key)")
                return false
            }
            if let largeValue = largeValue as? [String] {
                if let smallValue = value as? [String] {
                    if largeValue != smallValue {
                        print("Values as [String] mismatch for key: \(key) ")
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
    var dataManager: TealiumDataManager!

    override func setUp() {
        super.setUp()

        do {
            self.dataManager = try TealiumDataManager(account: account, profile: profile, environment: env)
        } catch _ {
            XCTFail("Unalbe to start data manager.")
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        // The compiler works...yay
        XCTAssertTrue(dataManager != nil)

    }

//    func testVolatileData(){
//        
//        // TODO: test arrays and other value types
//        
//        let testData = [
//            "a":"1",
//            "b":"2"
//        ]
//        
//        
//        dataManager.addVolatileData(testData as [String : AnyObject])
//        let volatileData = dataManager.getVolatileData()
//        
//        print("VolatileData: \(volatileData)")
//        
//        XCTAssertTrue(volatileData.contains(smallerDictionary: testData as [String : AnyObject]), "VolatileData: \(volatileData)")
//
//        dataManager.deleteVolatileData(["a","b"])
//        
//        let volatileDataPostDelete = dataManager.getVolatileData()
//        
//        XCTAssertFalse(volatileDataPostDelete.contains(smallerDictionary: testData as [String : AnyObject]), "VolatileData: \(volatileDataPostDelete)")
//    }

    // This test passes individually, not always as part of full test run.
    func testPersistentData() {
        // TODO: test arrays and other value types

        let testData = [
            "a": "1",
            "b": "2"
        ]

        dataManager.addPersistentData(testData as [String: AnyObject])

        guard let persistentData = dataManager.getPersistentData() else {
            XCTFail("test failed")
            return
        }

        XCTAssertTrue(persistentData.contains(smallerDictionary: testData as [String: AnyObject]), "PersistentData: \(persistentData)")

        dataManager.deletePersistentData(["a", "b"])

        guard let persistentDataPostDelete = dataManager.getPersistentData() else {
            XCTFail("test failed")
            return
        }

        XCTAssertFalse(persistentDataPostDelete.contains(smallerDictionary: testData as [String: AnyObject]), "PersistentData: \(persistentDataPostDelete)")

    }

    func testNewPersistentData() {
        var expected = [String: AnyObject]()
        expected[TealiumKey.libraryName] = "swift" as AnyObject?
        expected[TealiumKey.libraryVersion] = "1.1.0" as AnyObject?
        expected[TealiumKey.account] = account as AnyObject?
        expected[TealiumKey.profile] = profile as AnyObject?
        expected[TealiumKey.environment] = env as AnyObject?

        // Not testing tealium_visitor_id or tealium_vid

        let new = dataManager.newPersistentData()

        XCTAssertTrue(new.contains(smallerDictionary: expected))
    }

}
