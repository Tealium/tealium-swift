//
//  VisitorServiceConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum VisitorServiceConstants {
    static let moduleName = "visitorservice"
    static let refreshInterval = "visitor_service_refresh"
    static let enableVisitorService = "enable_visitor_service"
    static let pollingInterval = 5.0
    static let eventCountMetric = "22"
    static let defaultRefreshInterval: Double = 300
    static let visitorServiceDelegate = "visitor_service_delegate"
    static let visitorServiceOverrideProfile = "visitor_service_override_profile"
    static let visitorServiceOverrideURL = "visitor_service_override_url"
    static let defaultVisitorServiceDomain = "https://visitor-service.tealiumiq.com/"
}
