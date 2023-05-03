//
//  SessionManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public extension DataLayer {

    /// - Returns: `String?` session id for the active session.
    var sessionId: String? {
        get {
            persistentDataStorage?.removeExpired().all[TealiumDataKey.sessionId] as? String
        }
        set {
            if let newValue = newValue {
                // SessionId is formally part of the session data. It should have a session expiry,
                // But we need a way to know when this actually expires, so we need to change it to a custom date
                // And make it expire after the default time, while also refreshing its duration on each track call.
                add(data: [TealiumDataKey.sessionId: newValue], expiry: .afterCustom((.minutes, TealiumValue.defaultMinutesBetweenSession)))
            }
        }
    }

    /// Removes session data, generates a new session id, and sets the trigger session request flag.
    func refreshSessionData() {
        persistentDataStorage?.removeSessionData()
        sessionId = Date().unixTimeMilliseconds
        shouldTriggerSessionRequest = true
    }

    /// Checks if the session has expired in storage, if so, refreshes the session and saves the new data.
    func refreshSession() {
        guard let existingSessionId = sessionId else {
            if numberOfTrackRequests != 0 { // It is only 0 at initialization
                newTrackRequest() // Only track new request on actual track request, not on initialization
            }
            refreshSessionData()
            return
        }
        newTrackRequest()
        sessionId = existingSessionId
    }

    /// Calculates the number of track calls within the specified `secondsBetweenTrackEvents`
    /// property that will then determine if a new session shall be generated.
    func newTrackRequest() {
        let current = Date()
        if let lastTrackDate = lastTrackDate {
            if let date = lastTrackDate.addSeconds(secondsBetweenTrackEvents),
               date > current {
                let tracks = numberOfTrackRequests + 1
                if tracks == 2 { // To avoid multiple tracks to generate multiple simultaneous session API call
                    startNewSession(with: sessionStarter)
                }
            } else {
                numberOfTrackRequests = 0
            }
        }
        self.lastTrackDate = Date()
        numberOfTrackRequests += 1
    }

    /// If the tag management module is enabled and multiple tracks have been sent in given time, a new session is started.
    /// - Parameter sessionStarter: `SessionStarterProtocol`
    func startNewSession(with sessionStarter: SessionStarterProtocol) {
        if isTagManagementEnabled, shouldTriggerSessionRequest, config.sessionCountingEnabled {
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
