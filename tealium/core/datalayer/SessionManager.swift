//
//  SessionManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension DataLayer {

    /// Calculates the number of track calls within the specified `secondsBetweenTrackEvents`
    /// property that will then determine if a new session shall be generated.
    // swiftlint:disable unused_setter_value
    var numberOfTracks: Int {
        get {
            numberOfTrackRequests
        }
        set {
            let current = Date()
            if let lastTrackDate = lastTrackDate {
                if let date = lastTrackDate.addSeconds(secondsBetweenTrackEvents),
                   date > current {
                    let tracks = numberOfTrackRequests + 1
                    if tracks == 2 {
                        startNewSession(with: sessionStarter)
                    }
                } else {
                    self.lastTrackDate = Date()
                    numberOfTrackRequests = 0
                }
            }
            self.lastTrackDate = Date()
            numberOfTrackRequests += 1
        }
    }
    // swiftlint:enable unused_setter_value

    /// - Returns: `String?` session id for the active session.
    var sessionId: String? {
        get {
            persistentDataStorage?.removeExpired().all[TealiumKey.sessionId] as? String
        }
        set {
            if let newValue = newValue {
                add(data: [TealiumKey.sessionId: newValue], expiry: .session)
            }
        }
    }

    /// Removes session data, generates a new session id, and sets the trigger session request flag.
    func refreshSessionData() {
        sessionData = [String: Any]()
        sessionId = Date().unixTimeMilliseconds
        shouldTriggerSessionRequest = true
        add(key: TealiumKey.sessionId, value: sessionId ?? Date().unixTimeMilliseconds, expiry: .session)
    }

    /// Checks if the session has expired in storage, if so, refreshes the session and saves the new data.
    func refreshSession() {
        guard let existingSessionId = sessionId else {
            numberOfTracks = 0
            refreshSessionData()
            return
        }
        numberOfTracks += 1
        add(key: TealiumKey.sessionId, value: existingSessionId, expiry: .session)
    }

    /// If the tag management module is enabled and multiple tracks have been sent in given time, a new session is started.
    /// - Parameter sessionStarter: `SessionStarterProtocol`
    func startNewSession(with sessionStarter: SessionStarterProtocol) {
        if isTagManagementEnabled, shouldTriggerSessionRequest {
            sessionStarter.requestSession { [weak self] result in
                switch result {
                case .success:
                    self?.shouldTriggerSessionRequest = false
                    self?.numberOfTrackRequests = 0
                    self?.lastTrackDate = nil
                default:
                    break
                }
            }
        }
    }

}
