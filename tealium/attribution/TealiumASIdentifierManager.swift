//
//  TealiumASIdentifierManager.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import AdSupport
import Foundation
import UIKit

/// Testable replacement for Apple's ASIdentifierManager
public protocol TealiumASIdentifierManagerProtocol {
    static var shared: TealiumASIdentifierManagerProtocol { get }
    var advertisingIdentifier: String { get }
    var isAdvertisingTrackingEnabled: String { get }
    var identifierForVendor: String { get }
}

/// Implements Apple's ASIdenfifierManager to advertising identifiers
public class TealiumASIdentifierManager: TealiumASIdentifierManagerProtocol {
    var idManager = ASIdentifierManager.shared()

    public static var shared: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManager()

    private init() {

    }

    /// - Returns: String representation of IDFA
    public lazy var advertisingIdentifier: String = {
        return idManager.advertisingIdentifier.uuidString
    }()

    /// - Returns: String representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    public lazy var isAdvertisingTrackingEnabled: String = {
        return idManager.isAdvertisingTrackingEnabled.description
    }()

    /// - Returns: String representation of IDFV
    public lazy var identifierForVendor: String = {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }()
}
