//
//  DataLayerManagerProtocol.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TimestampCollection {
    var currentTimeStamps: [String: Any] { get }
}

public protocol DataLayerManagerProtocol: class {
    var all: [String: Any] { get set }
    var allSessionData: [String: Any] { get }
    var sessionId: String? { get set }
    var sessionData: [String: Any] { get set }
    func add(data: [String: Any], expiry: Expiry?)
    func add(key: String, value: Any, expiry: Expiry?)
    func joinTrace(id: String)
    func leaveTrace()
    func delete(for keys: [String])
    func delete(for key: String)
    func deleteAll()
}

protocol SessionManagerProtocol {
    var isTagManagementEnabled: Bool { get set }
    var minutesBetweenSessionIdentifier: TimeInterval { get set }
    var secondsBetweenTrackEvents: TimeInterval { get set }
    var sessionStarter: SessionStarterProtocol { get }
    func refreshSessionData()
    func refreshSession()
    func startNewSession(with sessionStarter: SessionStarterProtocol)
}

extension DataLayerManagerProtocol {

    func add(data: [String: Any], expiry: Expiry? = .session) {
        add(data: data, expiry: expiry)
    }

    func add(key: String, value: Any, expiry: Expiry? = .session) {
        add(key: key, value: value, expiry: expiry)
    }

}
