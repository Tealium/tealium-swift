//
//  TealiumVisitorProfileConstants.swift
//  tealium-swift
//
//  Created by Christina Sund on 5/13/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumVisitorProfileConstants {
    static let moduleName = "visitorservice"
    static let refreshInterval = "visitor_profile_refresh_interval"
    static let enableVisitorProfile = "enable_visitor_profile"
    static let pollingInterval = 5.0
    static let eventCountMetric = "22"
    static let defaultRefreshInterval: Int64 = 5
    static let visitorProfileDelegate = "visitor_profile_delegate"
}

public enum AttributeScope {
    case visitor
    case visit
}

public enum NetworkError: Error {
    case couldNotCreateSession
    case unknownResponseType
    case noInternet
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
}
