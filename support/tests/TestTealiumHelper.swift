//
//  TestTealiumHelper.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

enum TealiumTestKey {
    static let stringKey = "keyString"
    static let stringArrayKey = "keyArray"
}

enum TealiumTestValue {
    static let account = "testAccount"
    static let profile = "testProfile"
    static let environment = "testEnvironment"
    static let eventType = TealiumTrackType.event.description
    static let stringValue = "value"
    static let title = "testTitle"
    static let sessionId = "1234567890124"
    static let visitorID = "someVisitorId"
    static let random = "someRandomNumber"
    static let testIDFAString = "6D92078A-8246-4BA4-AE5B-76104861E7DC"
    static let testIDFAStringAdTrackingDisabled = "00000000-0000-0000-0000-000000000000"
    static let testIDFVString = "599F9C00-92DC-4B5C-9464-7971F01F8370"
}

let testStringArrayValue = ["value1", "value2"]
var testOptionalData = [TealiumTestKey.stringKey: TealiumTestValue.stringValue,
                        TealiumTestKey.stringArrayKey: testStringArrayValue] as [String: Any]
var testTealiumConfig: TealiumConfig { TealiumConfig(account: TealiumTestValue.account,
                                                     profile: TealiumTestValue.profile,
                                                     environment: TealiumTestValue.environment,
                                                     options: testOptionalData as [String: Any])
}

let testTrackRequest = TealiumTrackRequest(data: [:])

let testDataDictionary: [String: Any]  =
    [
        TealiumKey.account: TealiumTestValue.account,
        TealiumKey.profile: TealiumTestValue.profile,
        TealiumKey.environment: TealiumTestValue.environment,
        TealiumKey.event: TealiumTestValue.title,
        TealiumKey.libraryName: TealiumValue.libraryName,
        TealiumKey.libraryVersion: TealiumValue.libraryVersion,
        TealiumKey.sessionId: TealiumTestValue.sessionId,
        TealiumKey.visitorId: TealiumTestValue.visitorID,
        TealiumKey.random: TealiumTestValue.random
    ]

class TimeTraveler {

    private var date = Date()

    func travel(by timeInterval: TimeInterval) -> Date {
        return date.addingTimeInterval(timeInterval)
    }

    func generateDate() -> Date {
        return date
    }
}

class TestTealiumHelper {
    
    class func loadStub(from file: String,
                        _ cls: AnyClass) -> Data {
      let bundle = Bundle(for: cls)
      let url = bundle.url(forResource: file, withExtension: "json")
      return try! Data(contentsOf: url!)
    }
    
    class func context(with config: TealiumConfig, dataLayer: DataLayerManagerProtocol? = nil) -> TealiumContext {
        let tealium = Tealium(config: config)
        return TealiumContext(config: config, dataLayer: dataLayer ?? DummyDataManager(), tealium: tealium)
    }
    
    class func delay(_ completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion()
        }
    }

    class func allTealiumModuleNames() -> [String] {
        // priority order
        #if os(iOS)
        return [
            "location",
            "lifecycle",
            "autotracking",
            "attribution",
            "appdata",
            "devicedata",
            "connectivity",
            "collect",
            "tagmanagement",
            "remotecommands",
            "visitorservice"
        ]
        #elseif os(tvOS)
        return [
            "lifecycle",
            "appdata",
            "devicedata",
            "connectivity",
            "collect",
            "visitorservice"
        ]
        #else
        return [
            "lifecycle",
            "appdata",
            "devicedata",
            "connectivity",
            "collect",
            "visitorservice"
        ]
        #endif
    }

    func getConfig() -> TealiumConfig {
        return testTealiumConfig
    }

    func newConfig() -> TealiumConfig {
        return TealiumConfig(account: TealiumTestValue.account, profile: TealiumTestValue.profile, environment: TealiumTestValue.environment)
    }

    class func failingProtocols(testingList: [String],
                                passedList: [String]) -> [String] {
        var failingProtocols = [String]()

        for protocolName in testingList {
            if passedList.contains(protocolName) == false {
                failingProtocols.append(protocolName)
            }
        }

        return failingProtocols
    }

    class func missingStrings(fromArray: [String],
                              anotherArray: [String]) -> [String] {
        var missingStrings = [String]()

        for string in fromArray {
            if anotherArray.contains(string) == false {
                missingStrings.append(string)
            }
        }

        return missingStrings
    }

    // Didn't work as an extension for some reason.
    class func missingKeys(fromDictionary: [String: Any], keys: [String]) -> [String] {

        var missingKeys = [String]()

        for key in keys {
            guard fromDictionary[key] != nil else {
                missingKeys.append(key)
                continue
            }
        }

        return missingKeys
    }

}

extension TestTealiumHelper: ModuleDelegate {
    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {

    /// Allows dictionary to check if it contains keys and values from a smaller library
    ///
    /// - Paramaters:
    /// - otherDictionary: A [String:AnyObject] dictionary
    /// - Returns: Boolean answer
    func contains(otherDictionary: [String: Any]) -> Bool {
        // Should use generics here
        for (key, value) in self {
            guard let smallValue = otherDictionary[key as! String] else {
                print("Key missing from smaller dictionary: \(key)")
                return false
            }
            if String(describing: value) != String(describing: smallValue) {
                print("Values as String mismatch for key:\(key). Expected:\(value) returned:\(smallValue)")
                return false
            }
            if String(describing: value) != String(describing: smallValue) {
                print("Values as [String] mismatch for key:\(key). Expected:\(value) returned:\(smallValue)")
                return false
            }
        }

        return true
    }

}
