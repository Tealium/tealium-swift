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

public extension TealiumConfig {

    /// Sets the default refresh interval for visitor profile retrieval. Default is `.every(5, .minutes)`
    /// Set to `.every(0, .seconds)` if the profile should always be fetched following a track request.
    var visitorServiceRefresh: TealiumRefreshInterval? {
        get {
            options[VisitorServiceConstants.refreshInterval] as? TealiumRefreshInterval ?? .every(5, .minutes)
        }

        set {
            options[VisitorServiceConstants.refreshInterval] = newValue
        }
    }

    /// Visitor service delegates to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    var visitorServiceDelegate: VisitorServiceDelegate? {
        get {
            options[VisitorServiceConstants.visitorServiceDelegate] as? VisitorServiceDelegate
        }

        set {
            options[VisitorServiceConstants.visitorServiceDelegate] = newValue
        }
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).  If an invalid URL is passed, the default is used instead.
    /// Format: https://overridden-subdomain.yourdomain.com/
    var visitorServiceOverrideURL: String? {
        get {
            options[VisitorServiceConstants.visitorServiceOverrideURL] as? String
        }

        set {
            options[VisitorServiceConstants.visitorServiceOverrideURL] = newValue
        }
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    var visitorServiceOverrideProfile: String? {
        get {
            options[VisitorServiceConstants.visitorServiceOverrideProfile] as? String
        }

        set {
            options[VisitorServiceConstants.visitorServiceOverrideProfile] = newValue
        }
    }
}
