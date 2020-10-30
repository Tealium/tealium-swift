//
//  TealiumTrace.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension DataLayer {

    /// Adds traceId to the payload for debugging server side integrations.
    /// - Parameter id: `String` traceId from server side interface.
    func joinTrace(id: String) {
        add(key: TealiumKey.traceId, value: id, expiry: .session)
    }

    /// Ends the trace for the current session.
    func leaveTrace() {
        delete(for: TealiumKey.traceId)
    }
}

public extension Tealium {

    /// Sends a request to modules to initiate a trace with a specific Trace ID￼.
    ///
    /// - Parameter id: String representing the Trace ID
    func joinTrace(id: String) {
        dataLayer.joinTrace(id: id)
    }

    /// Sends a request to modules to leave a trace, and end the trace session￼.
    ///
    func leaveTrace() {
        dataLayer.leaveTrace()
    }

    /// Ends the current visitor session. Trace remains active, but visitor session is terminated.
    func killTraceVisitorSession() {
        guard let traceId = dataLayer.all[TealiumKey.traceId] as? String else {
            return
        }
        let dispatch = TealiumEvent(TealiumKey.killVisitorSession,
                                    dataLayer: [TealiumKey.killVisitorSessionEvent: TealiumKey.killVisitorSession, TealiumKey.callType: TealiumKey.killVisitorSession, TealiumKey.traceId: traceId])
        self.track(dispatch)
    }

    /// Handles deep links either for attribution purposes or joining/leaving a trace
    ///
    /// - Parameter link: `URL`
    func handleDeepLink(_ link: URL) {
        let queryItems = URLComponents(string: link.absoluteString)?.queryItems

        if let queryItems = queryItems,
           let traceId = extractTraceId(from: queryItems),
           zz_internal_modulesManager?.config.qrTraceEnabled == true {
            // Kill visitor session to trigger session end events
            // Session can be killed without needing to leave the trace
            if link.query?.contains(TealiumKey.killVisitorSession) == true {
                killTraceVisitorSession()
            }
            // Leave the trace and return - do not rejoin trace
            if link.query?.contains(TealiumKey.leaveTraceQueryParam) == true {
                leaveTrace()
                return
            }
            // Call join trace so long as this wasn't a leave trace request.
            joinTrace(id: traceId)
        }

        if zz_internal_modulesManager?.config.deepLinkTrackingEnabled == true {
            self.dataLayer.add(key: TealiumKey.deepLinkURL, value: link.absoluteString, expiry: .session)
            queryItems?.forEach {
                guard let value = $0.value else {
                    return
                }
                self.dataLayer.add(key: "\(TealiumKey.deepLinkQueryPrefix)_\($0.name)", value: value, expiry: .session)
            }
        }
    }

    fileprivate func extractTraceId(from queryItems: [URLQueryItem]) -> String? {
        for item in queryItems {
            if item.name == TealiumKey.traceIdQueryParam, let value = item.value {
                return value
            }
        }
        return nil
    }

}
