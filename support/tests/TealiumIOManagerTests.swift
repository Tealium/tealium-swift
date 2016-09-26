//
//  TealiumIOManagerTests.swift
//  tealium-swift
//
//  Created by Chad Hartman on 9/2/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import XCTest

class TealiumIOManagerTests: XCTestCase {
    
    let account  = "tealiummobile"
    let profile  = "demo"
    let env  = "dev"
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInit() {
        _ = createTestInstance()
    }
    
    func testSaveAndLoad() {
        guard let ioManager = createTestInstance() else {
            XCTFail("Could not startup the ioManager.")
            return
        }
        
        let data : [String: AnyObject] = ["foo": "foo string value" as AnyObject,
                                          "bar": ["alpha", "beta", "gamma"] as AnyObject]
   
        ioManager.saveData(data as [String : AnyObject]);
        
        if let loaded = ioManager.loadData() {
            XCTAssertTrue(loaded == data)
        } else {
            XCTFail()
        }
    }
    
    func testLoadCorruptedData() {
        let parentDir = "\(NSHomeDirectory())/.tealium/swift/"
        do {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch  {
            XCTFail()
        }
        let persistenceFilePath = "\(parentDir)/\(account)_\(profile)_\(env).data"
        
        let data:Data = "S*D&(*#@J".data(using: String.Encoding.utf8)!
        
        FileManager.default.createFile(atPath: persistenceFilePath,
                                                        contents:  data,
                                                        attributes: nil)
        
        guard let ioManager = createTestInstance() else {
            XCTFail("Could not startup the ioManager.")
            return
        }
        
        XCTAssertTrue(ioManager.loadData() == nil)
    }
    
    func testDelete() {
        guard let ioManager = createTestInstance() else {
            XCTFail("Could not startup the ioManager.")
            return
        }
        
        let data = ["foo": "foo string value", "bar": ["alpha", "beta", "gamma"]] as [String : Any]
        ioManager.saveData(data as [String : AnyObject])
        ioManager.deleteData()
        XCTAssertTrue(ioManager.loadData() == nil)
        XCTAssertTrue(!ioManager.persistedDataExists())
    }
    
    fileprivate func createTestInstance() -> TealiumIOManager? {
        
        return TealiumIOManager(account: account, profile: profile, env: env)
        
    }
    
}
