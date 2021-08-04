//
//  TealiumASIdentifierManager.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import AdSupport
import Foundation
#if !COCOAPODS
import TealiumCore
#endif
import UIKit
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

/// Testable replacement for Apple's ASIdentifierManager.
public protocol TealiumASIdentifierManagerProtocol {
    static var shared: TealiumASIdentifierManagerProtocol { get }
    var attManager: TealiumATTrackingManagerProtocol { get set }
    var advertisingIdentifier: String { get }
    var isAdvertisingTrackingEnabled: String { get }
    var identifierForVendor: String { get }
    var trackingAuthorizationStatus: String { get }
}

/// Testable replacement for Apple's ATTrackingManager.
public protocol TealiumATTrackingManagerProtocol {
    static var trackingAuthorizationStatus: UInt { get }
    var trackingAuthorizationStatusDescription: String { get }
}

class TealiumATTrackingManager: TealiumATTrackingManagerProtocol {
    static var trackingAuthorizationStatus: UInt {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus.rawValue
        } else {
            return 0
        }
    }
    
    var trackingAuthorizationStatusDescription: String {
        if #available(iOS 14, *) {
            return ATTrackingManager.AuthorizationStatus.string(from: ATTrackingManager.trackingAuthorizationStatus.rawValue)
        }
        return TealiumValue.unknown
    }
}

/// Implements Apple's ASIdenfifierManager to advertising identifiers.
public class TealiumASIdentifierManager: TealiumASIdentifierManagerProtocol {
    var idManager = ASIdentifierManager.shared()
    public var attManager: TealiumATTrackingManagerProtocol = TealiumATTrackingManager()

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManager()

    private init() {

    }

    /// - Returns: `String` representation of IDFA
    public var advertisingIdentifier: String {
        return idManager.advertisingIdentifier.uuidString
    }

    /// - Returns: `String` representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    public var isAdvertisingTrackingEnabled: String {
        if #available(iOS 14, *) {
            return trackingAuthorizationStatus == TrackingAuthorizationDescription.authorized ? "true" : "false"
        }
        return idManager.isAdvertisingTrackingEnabled.description
    }

    /// - Returns: `String` representation of ATTrackingManager.trackingAuthorizationStatus
    public var trackingAuthorizationStatus: String {
        return attManager.trackingAuthorizationStatusDescription
    }

    /// - Returns: `String` representation of IDFV
    public lazy var identifierForVendor: String = {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }()

}

@available(iOS 14, *)
public extension ATTrackingManager.AuthorizationStatus {
    static func string(from value: UInt) -> String {
        switch value {
        case 0:
            return TrackingAuthorizationDescription.notDetermined
        case 1:
            return TrackingAuthorizationDescription.restricted
        case 2:
            return TrackingAuthorizationDescription.denied
        default:
            return TrackingAuthorizationDescription.authorized
        }
    }
}

#endif
