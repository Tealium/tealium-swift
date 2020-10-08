//
//  Mocks.swift
//  TestHost
//
//  Created by Christina S on 8/12/20.
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

    required init(config: TealiumConfig, delegate: ModuleDelegate?, diskStorage: TealiumDiskStorageProtocol?, completion: ((Result<Bool, Error>, [String: Any]?)) -> Void) {
        self.config = config
        self.id = "Dummy"
    }

    var config: TealiumConfig {
        willSet {
            TealiumExpectations.expectations["configPropertyUpdateModule"]?.fulfill()
        }
    }

}

class DummyDataManager: DataLayerManagerProtocol {
    var all: [String: Any] = ["eventData": true, "sessionData": true]

    var allSessionData: [String: Any] = ["sessionData": true]

    var minutesBetweenSessionIdentifier: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var secondsBetweenTrackEvents: TimeInterval = TimeInterval(floatLiteral: 0.0)

    var sessionId: String?

    var sessionData: [String: Any] = ["sessionData": true]

    var sessionStarter: SessionStarterProtocol = SessionStarter(config: testTealiumConfig, urlSession: MockURLSessionSessionStarter())

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiry: Expiry?) {

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
