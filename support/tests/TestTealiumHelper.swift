//
//  TestTealiumHelper.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

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
    static let testIDFAResetString = "7U64320E-8765-2OK3-PO4K-12345678H8DS"
    static let testIDFAStringAdTrackingDisabled = "00000000-0000-0000-0000-000000000000"
    static let testIDFVString = "599F9C00-92DC-4B5C-9464-7971F01F8370"
}

let testStringArrayValue = ["value1", "value2"]
var testOptionalData = [TealiumTestKey.stringKey: TealiumTestValue.stringValue,
                        TealiumTestKey.stringArrayKey: testStringArrayValue] as [String: Any]
let testTealiumConfig: TealiumConfig = TealiumConfig(account: TealiumTestValue.account,
                                                     profile: TealiumTestValue.profile,
                                                     environment: TealiumTestValue.environment,
                                                     options: testOptionalData)

let testTrackRequest = TealiumTrackRequest(data: [:])

let testDataDictionary: [String: Any]  =
    [
        TealiumDataKey.account: TealiumTestValue.account,
        TealiumDataKey.profile: TealiumTestValue.profile,
        TealiumDataKey.environment: TealiumTestValue.environment,
        TealiumDataKey.event: TealiumTestValue.title,
        TealiumDataKey.libraryName: TealiumValue.libraryName,
        TealiumDataKey.libraryVersion: TealiumValue.libraryVersion,
        TealiumDataKey.sessionId: TealiumTestValue.sessionId,
        TealiumDataKey.visitorId: TealiumTestValue.visitorID,
        TealiumDataKey.random: TealiumTestValue.random
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
    
    class TestRetryManager {
        var queue: DispatchQueue
        var delay: TimeInterval?
        required init(queue: DispatchQueue, delay: TimeInterval?) {
            self.queue = queue
            self.delay = delay
        }
        
        func submit(completion: @escaping () -> Void) {
            if let delay = delay {
                queue.asyncAfter(deadline: .now() + delay, execute: completion)
           } else {
                queue.async {
                    completion()
                }
           }
        }
    }
    
    class func loadStub(from file: String,
                        _ cls: AnyClass) -> Data {
      let bundle = Bundle(for: cls)
      let url = bundle.url(forResource: file, withExtension: "json")
      return try! Data(contentsOf: url!)
    }
    
    class func context(with config: TealiumConfig, dataLayer: DataLayerManagerProtocol? = nil) -> TealiumContext {
        return TealiumContext(config: config, dataLayer: dataLayer ?? DummyDataManager())
    }
    
    class func delay(for delay: TimeInterval? = nil,
                     on queue: DispatchQueue = DispatchQueue(label: "test"),
                     _ completion: @escaping () -> Void) {
        let retry = TestRetryManager(queue: queue, delay: delay ?? 1.0)
        retry.submit {
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

extension Dictionary where Key == String, Value == Any {
    func equal(to dictionary: [String: Any] ) -> Bool {
        NSDictionary(dictionary: self).isEqual(to: dictionary)
    }
}

func XCTAssertString(_ string: String?, contains substring: String, file: StaticString = #filePath, line: UInt = #line) {
    guard let string = string else {
        XCTFail("Nil string can't contain \(substring)", file: file, line: line)
        return
    }
    XCTAssertTrue(string.range(of: substring) != nil, "String \(string) does not contain \(substring)", file: file, line: line)
}
