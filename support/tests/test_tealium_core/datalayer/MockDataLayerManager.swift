//
//  MockDataLayerManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore

class MockDataLayerManager: DataLayerManagerProtocol {
    var sessionDataBacking = [String: Any]()
    var addSingleCount = 0
    var addMultiCount = 0
    var deleteSingleCount = 0
    var deleteMultiCount = 0
    var deleteAllCount = 0

    var all: [String: Any] {
        get {
            ["all": "eventdata"]
        }
        set {
            self.add(data: newValue, expiration: .forever)
        }
    }

    var allSessionData: [String: Any] {
        ["all": "sessiondata"]
    }

    var minutesBetweenSessionIdentifier: TimeInterval = 1.0

    var secondsBetweenTrackEvents: TimeInterval = 1.0

    var sessionId: String? {
        get {
            "testsessionid"
        }
        set {
            self.add(data: ["sessionId": newValue!], expiration: .session)
        }
    }

    var sessionData: [String: Any] {
        get {
            ["session": "data"]
        }
        set {
            sessionDataBacking += newValue
        }
    }

    var sessionStarter: SessionStarterProtocol {
        MockTealiumSessionStarter()
    }

    var isTagManagementEnabled: Bool = true

    func add(data: [String: Any], expiration: Expiry) {
        addMultiCount += 1
    }

    func add(key: String, value: Any, expiration: Expiry) {
        addSingleCount += 1
    }

    func joinTrace(id: String) {

    }

    func delete(for keys: [String]) {
        deleteMultiCount += 1
    }

    func delete(for key: String) {
        deleteSingleCount += 1
    }

    func deleteAll() {
        deleteAllCount += 1
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
