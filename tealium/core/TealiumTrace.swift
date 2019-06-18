//
//  TealiumTrace.swift
//  tealium-swift
//
//  Created by Craig Rouse on 12/04/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Tealium {

    /// Sends a request to modules to initiate a trace with a specific Trace ID
    ///
    /// - Parameter traceId: String representing the Trace ID (usually 5-digit integer)
    func joinTrace(traceId: String) {
        self.config.optionalData[TealiumKey.traceId] = traceId
        let joinTraceRequest = TealiumJoinTraceRequest(traceId: traceId)
        self.modulesManager.tealiumModuleRequests(module: nil, process: joinTraceRequest)
    }

    /// Sends a request to modules to leave a trace, and end the trace session
    ///
    /// - Parameter killVisitorSession: Bool indicating whether the visitor session should be ended when the trace is left (default true).
    func leaveTrace(killVisitorSession: Bool = true) {
        let leaveTraceRequest = TealiumLeaveTraceRequest()
        self.modulesManager.tealiumModuleRequests(module: nil, process: leaveTraceRequest)
        if killVisitorSession {
            self.killVisitorSession()
        }
    }

    /// Ends the current visitor session. Trace remains active, but visitor session is terminated.
    func killVisitorSession() {
        guard let traceId = self.config.optionalData[TealiumKey.traceId] as? String else {
            return
        }
        self.track(title: TealiumKey.killVisitorSession, data: ["event": TealiumKey.killVisitorSession, "call_type": TealiumKey.killVisitorSession, TealiumKey.traceId: traceId], completion: nil)
    }
}
