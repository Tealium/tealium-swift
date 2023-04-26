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
        add(key: TealiumDataKey.traceId, value: id, expiry: .session)
    }

    /// Ends the trace for the current session.
    func leaveTrace() {
        delete(for: TealiumDataKey.traceId)
    }
}

public extension Tealium {

    enum DeepLinkReferrer {
        case url(_ url: URL)
        case app(_ identifier: String)

        public static func fromUrl(_ url: URL?) -> Self? {
            guard let url = url else { return nil }
            return .url(url)
        }

        public static func fromAppId(_ identifier: String?) -> Self? {
            guard let id = identifier else { return nil }
            return .app(id)
        }
    }

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
        guard let traceId = dataLayer.all[TealiumDataKey.traceId] as? String else {
            return
        }
        let dataLayer = [
            TealiumDataKey.killVisitorSessionEvent: TealiumKey.killVisitorSession,
            TealiumDataKey.traceId: traceId
        ]
        let dispatch = TealiumEvent(TealiumKey.killVisitorSession,
                                    dataLayer: dataLayer)
        self.track(dispatch)
    }

    /// Handles deep links either for attribution purposes or joining/leaving a trace
    ///
    /// - Parameter link: `URL`
    func handleDeepLink(_ link: URL, referrer: DeepLinkReferrer? = nil) {
        TealiumQueues.backgroundSerialQueue.async {
            let queryItems = URLComponents(string: link.absoluteString)?.queryItems

            if let queryItems = queryItems,
               let traceId = self.extractTraceId(from: queryItems),
               self.zz_internal_modulesManager?.config.qrTraceEnabled == true {
                // Kill visitor session to trigger session end events
                // Session can be killed without needing to leave the trace
                if link.query?.contains(TealiumKey.killVisitorSession) == true {
                    self.killTraceVisitorSession()
                }
                // Leave the trace and return - do not rejoin trace
                if link.query?.contains(TealiumKey.leaveTraceQueryParam) == true {
                    self.leaveTrace()
                    return
                }
                // Call join trace so long as this wasn't a leave trace request.
                self.joinTrace(id: traceId)
            }

            if self.zz_internal_modulesManager?.config.deepLinkTrackingEnabled == true {
                let oldQueryParamKeys: [String] = self.dataLayer.all.keys.filter { $0.starts(with: TealiumDataKey.deepLinkQueryPrefix) }
                self.dataLayer.delete(for: oldQueryParamKeys + [TealiumDataKey.deepLinkReferrerUrl, TealiumDataKey.deepLinkReferrerApp])
                var dataLayer = [String: Any]()
                switch referrer {
                case .url(let url):
                    dataLayer[TealiumDataKey.deepLinkReferrerUrl] = url.absoluteString
                case .app(let identifier):
                    dataLayer[TealiumDataKey.deepLinkReferrerApp] = identifier
                default:
                    break
                }
                dataLayer[TealiumDataKey.deepLinkURL] = link.absoluteString
                queryItems?.forEach {
                    guard let value = $0.value else {
                        return
                    }
                    dataLayer["\(TealiumDataKey.deepLinkQueryPrefix)_\($0.name)"] = value
                }
                self.dataLayer.add(data: dataLayer, expiry: .session)
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
