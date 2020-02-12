//
//  TealiumVisitorProfileConfigExtensions.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/16/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if visitorservice
import TealiumCore
#endif

public extension TealiumConfig {

    /// Sets the default refresh interval for visitor profile retrieval. Default is 5 minutes
    /// Set to `0` if the profile should always be fetched following a track request.
    /// - Parameter interval: `Int64` containing the refresh interval
    @available(*, deprecated, message: "Please switch to config.visitorServiceRefreshInterval")
    func setVisitorServiceRefresh(interval: Int64) {
        visitorServiceRefreshInterval = interval
    }

    /// Sets the default refresh interval for visitor profile retrieval. Default is 5 minutes
    /// Set to `0` if the profile should always be fetched following a track request.
    var visitorServiceRefreshInterval: Int64? {
        get {
            optionalData[TealiumVisitorProfileConstants.refreshInterval] as? Int64
        }

        set {
            optionalData[TealiumVisitorProfileConstants.refreshInterval] = newValue
        }
    }

    /// Adds a new visitor service delegate to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    /// - Parameter delegate: class conforming to `TealiumVisitorServiceDelegate`
    func addVisitorServiceDelegate(_ delegate: TealiumVisitorServiceDelegate) {
        var delegates = visitorServiceDelegates ?? [TealiumVisitorServiceDelegate]()
        delegates.append(delegate)
        visitorServiceDelegates = delegates
    }

    /// - Returns:`[TealiumVisitorServiceDelegate]?`
    @available(*, deprecated, message: "Please switch to config.visitorServiceDelegates")
    func getVisitorServiceDelegates() -> [TealiumVisitorServiceDelegate]? {
        visitorServiceDelegates
    }

    /// Visitor service delegates to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    var visitorServiceDelegates: [TealiumVisitorServiceDelegate]? {
        get {
            optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] as? [TealiumVisitorServiceDelegate]
        }

        set {
            optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] = newValue
        }
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).
    /// Format: https://overridden-subdomain.yourdomain.com/
    /// - Parameter url: `String` representing a valid URL. If an invalid URL is passed, the default is used instead.
    @available(*, deprecated, message: "Please switch to config.visitorServiceOverrideURL")
    func setVisitorServiceOverrideURL(_ url: String) {
        visitorServiceOverrideURL = url
    }

    /// - Returns: `String?` containing the URL from which to retieve the visitor profile.
    @available(*, deprecated, message: "Please switch to config.visitorServiceOverrideURL")
    func getVisitorServiceOverrideURL() -> String? {
        visitorServiceOverrideURL
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).  If an invalid URL is passed, the default is used instead.
    /// Format: https://overridden-subdomain.yourdomain.com/
    var visitorServiceOverrideURL: String? {
        get {
            optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideURL] as? String
        }

        set {
            optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideURL] = newValue
        }
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    /// - Parameter profile: `String` representing the profile name from which to retrieve the visitor profile.
    @available(*, deprecated, message: "Please switch to config.visitorServiceOverrideProfile")
    func setVisitorServiceOverrideProfile(_ profile: String) {
        visitorServiceOverrideProfile = profile
    }

    /// - Returns: `String?` containing the profile name from which to retrieve the visitor profile
    @available(*, deprecated, message: "Please switch to config.visitorServiceOverrideProfile")
    func getVisitorServiceOverrideProfile() -> String? {
        visitorServiceOverrideProfile
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    var visitorServiceOverrideProfile: String? {
        get {
            optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideProfile] as? String
        }

        set {
            optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideProfile] = newValue
        }
    }
}
