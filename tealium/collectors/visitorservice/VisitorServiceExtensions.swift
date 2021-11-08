//
//  VisitorServiceExtensions.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public extension Tealium {

    /// - Returns: `VisitorServiceManager` instance
    var visitorService: VisitorServiceManager? {
        (zz_internal_modulesManager?.modules.first {
            type(of: $0) == VisitorServiceModule.self
        } as? VisitorServiceModule)?.visitorServiceManager as? VisitorServiceManager
    }
}

public extension Collectors {
    static let VisitorService = VisitorServiceModule.self
}


extension TealiumConfigKey {
    static let refreshInterval = "visitor_service_refresh"
    static let enableVisitorService = "enable_visitor_service"
    static let visitorServiceDelegate = "visitor_service_delegate"
    static let visitorServiceOverrideProfile = "visitor_service_override_profile"
    static let visitorServiceOverrideURL = "visitor_service_override_url"
}

public extension TealiumConfig {

    /// Sets the default refresh interval for visitor profile retrieval. Default is `.every(5, .minutes)`
    /// Set to `.every(0, .seconds)` if the profile should always be fetched following a track request.
    var visitorServiceRefresh: TealiumRefreshInterval? {
        get {
            options[TealiumConfigKey.refreshInterval] as? TealiumRefreshInterval ?? .every(5, .minutes)
        }

        set {
            options[TealiumConfigKey.refreshInterval] = newValue
        }
    }

    /// Visitor service delegates to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    var visitorServiceDelegate: VisitorServiceDelegate? {
        get {
            let weakDelegate = options[TealiumConfigKey.visitorServiceDelegate] as? Weak<AnyObject>
            return weakDelegate?.value as? VisitorServiceDelegate
        }

        set {
            var weakDelegate: Weak<AnyObject>?
            if let newValue = newValue {
                weakDelegate = Weak<AnyObject>(value: newValue)
            }
            options[TealiumConfigKey.visitorServiceDelegate] = weakDelegate
        }
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).  If an invalid URL is passed, the default is used instead.
    /// Format: https://overridden-subdomain.yourdomain.com/
    var visitorServiceOverrideURL: String? {
        get {
            options[TealiumConfigKey.visitorServiceOverrideURL] as? String
        }

        set {
            options[TealiumConfigKey.visitorServiceOverrideURL] = newValue
        }
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    var visitorServiceOverrideProfile: String? {
        get {
            options[TealiumConfigKey.visitorServiceOverrideProfile] as? String
        }

        set {
            options[TealiumConfigKey.visitorServiceOverrideProfile] = newValue
        }
    }
}
