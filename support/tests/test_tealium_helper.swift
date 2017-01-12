//
//  test_tealium_helper.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/25/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

enum TealiumTestKey {
    static let stringKey = "keyString"
    static let stringArrayKey = "keyArray"
}

enum TealiumTestValue {
    static let account = "testAccount"
    static let profile = "testProfile"
    static let environment = "testEnviroment"
    static let eventType = TealiumTrackType.activity.description()
    static let stringValue = "value"
    static let title = "testTitle"
    static let sessionId = "1234567890124"
    static let visitorID = "someVisitorId"
    static let random = "someRandomNumber"
}

enum TealiumTestError : Error {
    case generic
}

let testStringArrayValue = ["value1", "value2"]
var testOptionalData = [TealiumTestKey.stringKey: TealiumTestValue.stringValue,
                        TealiumTestKey.stringArrayKey: testStringArrayValue] as [String : Any]
let testTealiumConfig = TealiumConfig(account:TealiumTestValue.account,
                                      profile:TealiumTestValue.profile,
                                      environment:TealiumTestValue.environment,
                                      optionalData:testOptionalData as [String : Any])

let testDataDictionary : [String:Any]  =
    [
        TealiumKey.account : TealiumTestValue.account,
        TealiumKey.profile : TealiumTestValue.profile,
        TealiumKey.environment : TealiumTestValue.environment,
        TealiumKey.event : TealiumTestValue.title,
        TealiumKey.eventName : TealiumTestValue.title,
        TealiumKey.eventType :  TealiumTestValue.eventType,
        TealiumKey.libraryName : TealiumValue.libraryName,
        TealiumKey.libraryVersion : TealiumValue.libraryVersion,
        TealiumVolatileDataKey.sessionId : TealiumTestValue.sessionId,
        TealiumAppDataKey.visitorId :TealiumTestValue.visitorID,
        TealiumAppDataKey.legacyVid : TealiumTestValue.visitorID,
        TealiumVolatileDataKey.random : TealiumTestValue.random
    ]

class test_tealium_helper {
    
    var callBack : ((TealiumModule, String)->Void)?
    
    class func testTrack() -> TealiumTrack {
        return TealiumTrack(data: [String:AnyObject](),
                            info: nil,
                            completion: nil)
    }
    
    // Any subclass of the TealiumModule must eventually trigger it's protocol
    //  for the ModulesManager to work properly.
    
    func didReceiveCallBack(completion:((_ module: TealiumModule, _ protocolName: String)->Void)?){
        callBack = completion
    }
    
    /**
     All modules should callback to their delegate a success or failure for the following functions:
        - enable
        - disable
        - track
        - process
     */
    func modulesReturnsMinimumProtocols(module: TealiumModule) -> (success: Bool, protocolsFailing: [String]){
        
        var succeedingProtocols = [String]()
        
        didReceiveCallBack { (module, protocolName) in
            
            succeedingProtocols.append(protocolName)
        }
                
        module.delegate = self
        
        // The 4 standard calls
        module.enable(config: testTealiumConfig)
        module.disable()
        
        let testTrack = TealiumTrack(data: [String:AnyObject](),
                                     info: nil,
                                     completion: nil)
        module.track(testTrack)
        
        usleep(100000) // Millionth of seconds - Delay Since we arent using XCTest waitForExpectations directly
        
        let failingProtocols = failingMininmumProtocols(succeedingProtocols: succeedingProtocols)
        
        return (failingProtocols.count == 0, failingProtocols)
        
    }
    
    /**
     Returns names of any protocols not properly implemented
     */
    private func failingMininmumProtocols(succeedingProtocols: [String]) -> [String] {
        
        let minimumProtocols = [TestTealiumModuleProtocolKey.enable,
                                 TestTealiumModuleProtocolKey.disable,
                                 TestTealiumModuleProtocolKey.track]
        
        var failingProtocols = [String]()
        
        for minimumProtocol in minimumProtocols {
            if succeedingProtocols.contains(minimumProtocol) == false {
                failingProtocols.append(minimumProtocol)
            }
        }
        
        return failingProtocols
    }
    
    // Didn't work as an extension for some reason.
    class func missingKeys(fromDictionary: [String:Any], keys:[String])-> [String] {
        
        var missingKeys = [String]()
        
        for key in keys {
            guard let _ = fromDictionary[key] else {
                missingKeys.append(key)
                continue
            }
        }
        
        return missingKeys
    }
}

enum TestTealiumModuleProtocolKey {
    static let enable = "enable"
    static let disable = "disable"
    static let track = "track"
}

extension test_tealium_helper : TealiumModuleDelegate {
    
    func tealiumModuleFinishedReport(fromModule: TealiumModule, module: TealiumModule, process: TealiumProcess) {
        
    }
    
    func tealiumModuleFinished(module: TealiumModule, process: TealiumProcess) {
        
        switch process.type {
        case .enable:
            callBack?(module, TestTealiumModuleProtocolKey.enable)
        case .disable:
            callBack?(module, TestTealiumModuleProtocolKey.disable)
        case .track:
            callBack?(module, TestTealiumModuleProtocolKey.track)
        }
        
    }
    
    func tealiumModuleRequests(module: TealiumModule, process: TealiumProcess) {
        
    }
    
}


extension Dictionary where Key:ExpressibleByStringLiteral, Value:Any{
    
    /**
     Allows dictionary to check if it contains keys and values from a smaller library
     
     - Paramaters:
     - smallerDictionary: A [String:AnyObject] dictionary
     - Returns: Boolean answer
     */
    func contains(smallerDictionary:[String:Any])-> Bool {
        
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

