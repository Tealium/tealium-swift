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
    func setVisitorServiceRefresh(interval: Int64) {
        optionalData[TealiumVisitorProfileConstants.refreshInterval] = interval
    }

    /// Adds a new visitor service delegate to be notified of any changes to the visitor profile.
    /// Note: if no delegates are registered, no requests will be made to fetch the visitor profile from the server.
    /// - Parameter delegate: class conforming to `TealiumVisitorServiceDelegate`
    func addVisitorServiceDelegate(_ delegate: TealiumVisitorServiceDelegate) {
        var delegates = getVisitorServiceDelegates() ?? [TealiumVisitorServiceDelegate]()
        delegates.append(delegate)
        optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] = delegates
    }

    /// - Returns:`[TealiumVisitorServiceDelegate]?`
    func getVisitorServiceDelegates() -> [TealiumVisitorServiceDelegate]? {
        return optionalData[TealiumVisitorProfileConstants.visitorProfileDelegate] as? [TealiumVisitorServiceDelegate]
    }

    /// Overrides the default visitor service URL (visitor-service.tealiumiq.com).
    /// Format: https://overridden-subdomain.yourdomain.com/
    /// - Parameter url: `String` representing a valid URL. If an invalid URL is passed, the default is used instead.
    func setVisitorServiceOverrideURL(_ url: String) {
        optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideURL] = url
    }

    /// - Returns: `String?` containing the URL from which to retieve the visitor profile.
    func getVisitorServiceOverrideURL() -> String? {
        return optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideURL] as? String
    }

    /// Sets a specific overridden profile from which to fetch the visitor profile.
    /// - Parameter profile: `String` representing the profile name from which to retrieve the visitor profile.
    func setVisitorServiceOverrideProfile(_ profile: String) {
        optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideProfile] = profile
    }

    /// - Returns: `String?` containing the profile name from which to retrieve the visitor profile
    func getVisitorServiceOverrideProfile() -> String? {
        return optionalData[TealiumVisitorProfileConstants.visitorServiceOverrideProfile] as? String
    }

}
