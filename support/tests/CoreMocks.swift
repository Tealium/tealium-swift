//
//  CoreMocks.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
import XCTest

class TealiumExpectations {
    static var expectations = [String: XCTestExpectation]()
}

class DummyCollector: Collector, DispatchListener, DispatchValidator {

    var id: String

    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?) {
        return (false, nil)
    }

    func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }

    func shouldPurge(request: TealiumRequest) -> Bool {
        return false
    }

    func willTrack(request: TealiumRequest) {

    }

    var data: [String: Any]? {
        ["dummy": true]
    }

    required init(context: TealiumContext, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.config = context.config
        self.id = "Dummy"
    }

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdateModule"]?.fulfill()
        }
    }

}

class DummyDataManager: DataLayerManagerProtocol {
    var addCount = 0

    var all: [String: Any] = ["eventData": true, "sessionData": true]

    var allSessionData: [String: Any] = ["sessionData": true]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = ["sessionData": true]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: testTealiumConfig, urlSession: MockURLSessionSessionStarter())

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry?) {
        addCount += 1
    }

    func add(key: String, value: Any, expiry: Expiry?) {

    }

    func joinTrace(id: String) {

    }

    func delete(for Keys: [String]) {

    }

    func delete(for key: String) {

    }

    func deleteAll() {

    }

    func leaveTrace() {

    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}

class DummyDispatchManagerConfigUpdate: DispatchManagerProtocol {
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?
    
    var timedEventScheduler: Schedulable?

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdate"]?.fulfill()
            //TealiumModulesManagerTests.expectatations["configPropertyUpdate"] = nil
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {

    }

    func handleDequeueRequest(reason: String) {

    }

}

class DummyDispatchManagerdequeue: DispatchManagerProtocol {
    var dispatchers: [Dispatcher]?

    var dispatchListeners: [DispatchListener]?

    var dispatchValidators: [DispatchValidator]?

    var asyncExpectation: XCTestExpectation?
    
    var timedEventScheduler: Schedulable?

    var config: TealiumConfig {
        willSet {
            guard let expectation = asyncExpectation else {
                return
            }
            expectation.fulfill()
        }
    }

    required init(dispatchers: [Dispatcher]?, dispatchValidators: [DispatchValidator]?, dispatchListeners: [DispatchListener]?, connectivityManager: ConnectivityModule, config: TealiumConfig) {
        self.dispatchers = dispatchers
        self.dispatchValidators = dispatchValidators
        self.dispatchListeners = dispatchListeners
        self.config = config
    }

    func processTrack(_ request: TealiumTrackRequest) {

    }

    func handleDequeueRequest(reason: String) {
        guard let expectation = asyncExpectation else {
            return
        }
        expectation.fulfill()
        asyncExpectation = XCTestExpectation(description: "\(expectation.description)1")
    }

}

class DummyDataManagerNoData: DataLayerManagerProtocol {
    var all: [String: Any] = [:]

    var allSessionData: [String: Any] = [:]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = [:]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: testTealiumConfig, urlSession: MockURLSessionSessionStarter())

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry) {

    }

    func add(key: String, value: Any, expiry: Expiry) {

    }

    func joinTrace(id: String) {

    }

    func delete(for Keys: [String]) {

    }

    func delete(for key: String) {

    }

    func deleteAll() {

    }

    func leaveTrace() {

    }

    func refreshSessionData() {

    }

    func sessionRefresh() {

    }

    func startNewSession(with sessionStarter: SessionStarterProtocol) {

    }

}

class DummyDispatcher: Dispatcher {
    var isReady: Bool = true

    required init(config: TealiumConfig, delegate: ModuleDelegate, completion: ModuleCompletion?) {
        self.config = config
    }

    func dynamicTrack(_ request: TealiumRequest, completion: ModuleCompletion?) {
    }

    var id: String = "DummyDispatcher"

    var config: TealiumConfig

}

// MARK: Migrator Mocks

class MockMigrator: Migratable {
    var migrateCount = 0
    func migratePersistent(dataLayer: DataLayerManagerProtocol) {
        migrateCount += 1
    }
}

class MockUserDefaultsConsent: Storable {

    var objectCount = 0
    var removeCount = 0

    func object(forKey defaultName: String) -> Any? {
        objectCount += 1
        let mockData = NSKeyedArchiver.archivedData(withRootObject: MockTEALConsentConfiguration())
        UserDefaults.standard.set(mockData, forKey: "mockDataConsent")
        return UserDefaults.standard.data(forKey: "mockDataConsent")
    }

    func removeObject(forKey defaultName: String) {
        removeCount += 1
    }
}

class MockUserDefaultsConsentNoData: Storable {
    func object(forKey defaultName: String) -> Any? {
        nil
    }

    func removeObject(forKey defaultName: String) {
    }
}

class MockLegacyUserDefaults: Storable {

    var objectCount = 0
    var removeCount = 0
    static let mockData = [LifecycleKey.firstLaunchDate: "2020-10-12T18:22:12Z",
                           LifecycleKey.firstLaunchDateMMDDYYYY: "10/12/2020",
                           LifecycleKey.lastLaunchDate: "2020-10-12T18:22:22Z",
                           LifecycleKey.lastWakeDate: "2020-10-12T17:02:04Z",
                           LifecycleKey.launchCount: "12",
                           LifecycleKey.priorSecondsAwake: "10",
                           LifecycleKey.sleepCount: "5",
                           LifecycleKey.totalCrashCount: "2",
                           LifecycleKey.totalLaunchCount: "12",
                           LifecycleKey.totalSecondsAwake: "3000",
                           LifecycleKey.totalSleepCount: "8",
                           LifecycleKey.totalWakeCount: "7",
                           LifecycleKey.wakeCount: "7",
                           TealiumKey.visitorId: "205CA6D0FE3A4242A3522DBE7F5B75DE",
                           TealiumKey.uuid: "205CA6D0-FE3A-4242-A352-2DBE7F5B75DE",
                           "custom_persistent_key": "customValue"]

    func object(forKey defaultName: String) -> Any? {
        objectCount += 1
        return MockLegacyUserDefaults.mockData
    }

    func removeObject(forKey defaultName: String) {
        removeCount += 1
    }
}

class MockLegacyUserDefaultsNoData: Storable {
    func object(forKey defaultName: String) -> Any? {
        nil
    }

    func removeObject(forKey defaultName: String) {
    }
}

class MockUnarchiverConsent: Unarchivable {

    var setClassCount = 0
    static var unarchiveCount = 0

    func setClass(_ cls: AnyClass?, forClassName codedName: String) {
        setClassCount += 1
    }

    static func unarchiveTopLevelObjectWithData(_ data: Data) throws -> Any? {
        unarchiveCount += 1
        return MockConsentConfiguration()
    }
}

class MockUnarchiverConsentNoData: Unarchivable {

    func setClass(_ cls: AnyClass?, forClassName codedName: String) {
    }

    static func unarchiveTopLevelObjectWithData(_ data: Data) throws -> Any? {
        nil
    }
}

class MockConsentConfiguration: ConsentConfigurable {
    var consentStatus: Int = 1
    var consentCategories: [String] = [TealiumConsentCategories.affiliates.rawValue,
                                       TealiumConsentCategories.bigData.rawValue,
                                       TealiumConsentCategories.crm.rawValue,
                                       TealiumConsentCategories.engagement.rawValue]
    var enableConsentLogging: Bool = true
}

class MockTEALConsentConfiguration: NSObject, NSSecureCoding {

    var consentStatus: Int
    var consentCategories: [String]
    var enableConsentLogging: Bool

    public static var supportsSecureCoding: Bool {
        true
    }

    override public init() {
        self.consentStatus = 1
        self.enableConsentLogging = true
        self.consentCategories = [TealiumConsentCategories.affiliates.rawValue,
                                  TealiumConsentCategories.bigData.rawValue,
                                  TealiumConsentCategories.crm.rawValue,
                                  TealiumConsentCategories.engagement.rawValue]
    }

    required public init?(coder: NSCoder) {
        self.consentStatus = 1
        self.enableConsentLogging = true
        self.consentCategories = [TealiumConsentCategories.affiliates.rawValue,
                                  TealiumConsentCategories.bigData.rawValue,
                                  TealiumConsentCategories.crm.rawValue,
                                  TealiumConsentCategories.engagement.rawValue]
    }

    public func encode(with: NSCoder) {
        with.encode(self.consentStatus, forKey: MigrationKey.consentStatus)
        with.encode(self.enableConsentLogging, forKey: MigrationKey.consentLogging)
        with.encode(self.consentCategories, forKey: MigrationKey.consentCategories)
    }

}

class MockMigratedDataLayer: DataLayerManagerProtocol {

    var deleteCount = 0

    static let mockData: [String: Any] = [LifecycleKey.migratedLifecycle:
                                            [LifecycleKey.firstLaunchDate: "2020-10-12T18:22:12Z",
                                             LifecycleKey.firstLaunchDateMMDDYYYY: "10/12/2020",
                                             LifecycleKey.lastLaunchDate: "2020-10-12T18:22:22Z",
                                             LifecycleKey.lastWakeDate: "2020-10-12T17:02:04Z",
                                             LifecycleKey.launchCount: 12,
                                             LifecycleKey.priorSecondsAwake: 10,
                                             LifecycleKey.sleepCount: 5,
                                             LifecycleKey.totalCrashCount: 2,
                                             LifecycleKey.totalLaunchCount: 12,
                                             LifecycleKey.totalSecondsAwake: 3000,
                                             LifecycleKey.totalSleepCount: 8,
                                             LifecycleKey.totalWakeCount: 7,
                                             LifecycleKey.wakeCount: 7],
                                          TealiumKey.visitorId: "205CA6D0FE3A4242A3522DBE7F5B75DE",
                                          TealiumKey.uuid: "205CA6D0-FE3A-4242-A352-2DBE7F5B75DE",
                                          "custom_persistent_key": "customValue",
                                          ConsentKey.consentStatus: 1,
                                          ConsentKey.consentLoggingEnabled: true,
                                          ConsentKey.consentCategoriesKey: [TealiumConsentCategories.affiliates.rawValue,
                                                                            TealiumConsentCategories.bigData.rawValue,
                                                                            TealiumConsentCategories.crm.rawValue,
                                                                            TealiumConsentCategories.engagement.rawValue]]

    var all: [String: Any] {
        get {
            MockMigratedDataLayer.mockData
        }
        set {

        }
    }

    var allSessionData: [String: Any] {
        get {
            all
        }
        set {

        }
    }

    var sessionId: String?

    var sessionData: [String: Any] {
        get {
            all
        }
        set {

        }
    }

    func joinTrace(id: String) {

    }

    func leaveTrace() {

    }

    func delete(for keys: [String]) {
        deleteCount += 1
    }

    func delete(for key: String) {
        deleteCount += 1
    }

    func deleteAll() {

    }

}

class MockMigratedDataLayerNoData: DataLayerManagerProtocol {

    var all: [String: Any] {
        get {
            [String: Any]()
        }
        set {

        }
    }

    var allSessionData: [String: Any] {
        get {
            all
        }
        set {

        }
    }

    var sessionId: String?

    var sessionData: [String: Any] {
        get {
            all
        }
        set {

        }
    }

    func joinTrace(id: String) {

    }

    func leaveTrace() {

    }

    func delete(for keys: [String]) {

    }

    func delete(for key: String) {
    }

    func deleteAll() {

    }

}

class MockTimedEventScheduler: Schedulable {

    var id: String = "MockTimedEventScheduler"
    var startCallCount = 0
    var stopCallCount = 0
    var shouldQueueCallCount = 0
    var sendTimedEventCount = 0
    var cancelCallCount = 0
    var clearAllCallCount = 0
    
    var events =  [String : TimedEvent]()
    
    func shouldQueue(request: TealiumRequest) -> (Bool, [String : Any]?) {
        shouldQueueCallCount += 1
        return (false, [String: Any]())
    }
    
    func shouldDrop(request: TealiumRequest) -> Bool {
        return false
    }
    
    func shouldPurge(request: TealiumRequest) -> Bool {
        return false
    }
    
    func start(event name: String, with data: [String : Any]?) {
        startCallCount += 1
    }
    
    func stop(event name: String) -> TimedEvent? {
        stopCallCount += 1
        return TimedEvent(name: "test")
    }
    
    func sendTimedEvent(_ event: TimedEvent) {
        sendTimedEventCount += 1
    }
    
    func cancel(event name: String) {
        cancelCallCount += 1
    }
    
    func clearAll() {
        clearAllCallCount += 1
    }
    
}
