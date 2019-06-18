//
//  TestTealiumHelper.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/25/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import Tealium

enum TealiumTestKey {
    static let stringKey = "keyString"
    static let stringArrayKey = "keyArray"
}

enum TealiumTestValue {
    static let account = "testAccount"
    static let profile = "testProfile"
    static let environment = "testEnvironment"
    static let eventType = TealiumTrackType.event.description()
    static let stringValue = "value"
    static let title = "testTitle"
    static let sessionId = "1234567890124"
    static let visitorID = "someVisitorId"
    static let random = "someRandomNumber"
    static let testIDFAString = "6D92078A-8246-4BA4-AE5B-76104861E7DC"
    static let testIDFAStringAdTrackingDisabled = "00000000-0000-0000-0000-000000000000"
    static let testIDFVString = "599F9C00-92DC-4B5C-9464-7971F01F8370"
}

enum TealiumTestError: Error {
    case generic
}

let testStringArrayValue = ["value1", "value2"]
var testOptionalData = [TealiumTestKey.stringKey: TealiumTestValue.stringValue,
                        TealiumTestKey.stringArrayKey: testStringArrayValue] as [String: Any]
let testTealiumConfig = TealiumConfig(account: TealiumTestValue.account,
                                      profile: TealiumTestValue.profile,
                                      environment: TealiumTestValue.environment,
                                      optionalData: testOptionalData as [String: Any])

let testDeleteRequest = TealiumDeleteRequest(name: "testDelete")
let testDisableRequest = TealiumDisableRequest()
let testEnableRequest = TealiumEnableRequest(config: testTealiumConfig, enableCompletion: nil)
let testLoadRequest = TealiumLoadRequest(name: "test") { (_, _, _) in
    // Future processing... maybe
}
let testReportNotificationRequest = TealiumReportNotificationsRequest()
let testSaveRequest = TealiumSaveRequest(name: "test", data: ["key": "value"])
let testTrackRequest = TealiumTrackRequest(data: [:],
                                           completion: nil)

let testDataDictionary: [String: Any]  =
    [
        TealiumKey.account: TealiumTestValue.account,
        TealiumKey.profile: TealiumTestValue.profile,
        TealiumKey.environment: TealiumTestValue.environment,
        TealiumKey.event: TealiumTestValue.title,
        TealiumKey.libraryName: TealiumValue.libraryName,
        TealiumKey.libraryVersion: TealiumValue.libraryVersion,
        TealiumVolatileDataKey.sessionId: TealiumTestValue.sessionId,
        TealiumAppDataKey.visitorId: TealiumTestValue.visitorID,
        TealiumVolatileDataKey.random: TealiumTestValue.random
    ]

class TestTealiumHelper {

    var callBack: ((TealiumModule, String) -> Void)?
    var succeedingProtocols = [String]()
    var successfulRequests = [TealiumRequest]()
    var testCompletion : ((_ success: Bool, _ protocolsFailing: [String]) -> Void)?

    class func testTrack() -> TealiumTrackRequest {
        return TealiumTrackRequest(data: [String: AnyObject](),
                                   completion: nil)
    }

    // Any subclass of the TealiumModule must eventually trigger its protocol
    // for the ModulesManager to work properly.

    func didReceiveCallBack(completion:((_ module: TealiumModule, _ protocolName: String) -> Void)?) {
        callBack = completion
    }

    func modulesProcessRequests(module: TealiumModule,
                                protocolsList: [String],
                                execution: (() -> Void),
                                completion: ((_ success: Bool, _ protocolsFailing: [String]) -> Void)?) {
        var succeedingProtocols = [String]()

        didReceiveCallBack { _, protocolName in
            succeedingProtocols.append(protocolName)

            if succeedingProtocols.count == protocolsList.count {
                let failing = TestTealiumHelper.failingProtocols(testingList: protocolsList,
                                                                 passedList: succeedingProtocols)
                completion?(true, failing)
            }
        }

        module.delegate = self
        execution()
    }

    class func allTealiumModuleNames() -> [String] {
        // priority order
        #if os(iOS)
        return [
            "logger",
            "lifecycle",
            "autotracking",
            "filestorage",
            "defaultsstorage",
            "attribution",
            "appdata",
            "datasource",
            "devicedata",
            "persistentdata",
            "volatiledata",
            "delegate",
            "connectivity",
            "collect",
            "tagmanagement",
            "remotecommands",
            //            "crash", // crash is excluded; separate tests exist for crash
            "consentmanager",
            "dispatchqueue",
        ]
        #elseif os(tvOS)
        return [
            "logger",
            "lifecycle",
            "autotracking",
            "filestorage",
            "defaultsstorage",
            "appdata",
            "datasource",
            "devicedata",
            "persistentdata",
            "volatiledata",
            "delegate",
            "connectivity",
            "collect",
            "consentmanager",
            "dispatchqueue",
        ]
        #else
            return [
                "logger",
                "lifecycle",
                // "autotracking",
                "filestorage",
                "defaultsstorage",
                // "attribution",
                "appdata",
                "datasource",
                "devicedata",
                "persistentdata",
                "volatiledata",
                "delegate",
                "connectivity",
                "collect",
                // "tagmanagement",
                "consentmanager",
                "dispatchqueue",
            ]
        #endif
    }

    class func allTealiumRequestNames() -> [String] {

        return [
            TealiumEnableRequest.instanceTypeId(),
            TealiumDeleteRequest.instanceTypeId(),
            TealiumDisableRequest.instanceTypeId(),
            TealiumLoadRequest.instanceTypeId(),
            TealiumReportNotificationsRequest.instanceTypeId(),
            TealiumSaveRequest.instanceTypeId(),
            TealiumTrackRequest.instanceTypeId(),
        ]

    }

    func getConfig() -> TealiumConfig {
        return testTealiumConfig
    }

    func newConfig() -> TealiumConfig {
        return TealiumConfig(account: TealiumTestValue.account, profile: TealiumTestValue.profile, environment: TealiumTestValue.environment)
    }

    class func allTestTealiumRequests() -> [TealiumRequest] {
        return [
            testDeleteRequest,
            testDisableRequest,
            testEnableRequest,
            testLoadRequest,
            testReportNotificationRequest,
            testSaveRequest,
            testTrackRequest,
        ]
    }

    class func executeAllKnownTealiumRequests(forModule: TealiumModule) {
        forModule.handle(testDeleteRequest)
        forModule.handle(testDisableRequest)
        forModule.handle(testEnableRequest)
        forModule.handle(testLoadRequest)
        forModule.handle(testReportNotificationRequest)
        forModule.handle(testSaveRequest)
        forModule.handle(testTrackRequest)
    }

    // Will not work for async modules
    func failingRequestsFor(module: TealiumModule) -> [TealiumRequest] {
        successfulRequests.removeAll()
        let allTestRequests = TestTealiumHelper.allTestTealiumRequests()
        var failing = [TealiumRequest]()
        module.delegate = self

        for request in allTestRequests {
            // fire
            module.handle(request)

            // check callback
            if request.typeId != successfulRequests.last?.typeId {
                failing.append(request)
            }
        }
        return failing
    }

    /// Checks that module will return from all standard tealium request types
    ///
    /// - Parameters:
    ///   - module: Module to test
    ///   - completion: Completion called when checks finished.
    func modulesReturnsMinimumProtocols(module: TealiumModule,
                                        completion: @escaping ((_ success: Bool, _ protocolsFailing: [String]) -> Void)) {
        testCompletion = completion
        successfulRequests.removeAll()
        let allTestRequests = TestTealiumHelper.allTestTealiumRequests()
//        var failing = [String]()
        module.delegate = self

        for request in allTestRequests {

            // fire
            module.handle(request)

//            // check callback
//            if successfulRequests.last == nil {
//                failing.append(request.typeId)
//                continue
//            }
//            if request.typeId != successfulRequests.last!.typeId {
//                failing.append(request.typeId)
//            }

        }

//        completion(failing.isEmpty ? true : false, failing)
    }

    func areTestsFinished() -> Bool {
        return successfulRequests.count >= TestTealiumHelper.allTestTealiumRequests().count
    }

    func stringsFrom(_ array: [TealiumRequest]) -> [String] {
        var result = [String]()
        for request in array {
            result.append(request.typeId)
        }
        return result
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

extension TestTealiumHelper: TealiumModuleDelegate {

    func tealiumModuleFinished(module: TealiumModule, process: TealiumRequest) {
        // NOTE: Don't leave a breakpoint in here, can throw off the test
        callBack?(module, process.typeId)
        successfulRequests.append(process)

        if areTestsFinished() {
            let successStrings = stringsFrom(successfulRequests)
            let failing = TestTealiumHelper.failingProtocols(testingList: TestTealiumHelper.allTealiumRequestNames(),
                                                             passedList: successStrings)
            testCompletion?(failing.isEmpty ? true : false, failing)
        }

    }

    func tealiumModuleRequests(module: TealiumModule?, process: TealiumRequest) {

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
