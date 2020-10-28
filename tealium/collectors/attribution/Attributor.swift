//
//  Attributor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
import StoreKit

public protocol Attributable: class {
    @available(iOS 11.3, *)
    static func registerAppForAdNetworkAttribution()
    @available(iOS 14.0, *)
    static func updateConversionValue(_ conversionValue: Int)
}

public extension Attributable {
    static func registerAppForAdNetworkAttribution() { }
    static func updateConversionValue(_ conversionValue: Int) { }
}

public class Attributor: Attributable {

    public init() { }

    public static func registerAppForAdNetworkAttribution() {
        #if os(iOS)
        if #available(iOS 11.3, *) {
            SKAdNetwork.registerAppForAdNetworkAttribution()
        }
        #endif
    }

    public static func updateConversionValue(_ conversionValue: Int) {
        #if os(iOS)
        if #available(iOS 14.0, *) {
            SKAdNetwork.updateConversionValue(conversionValue)
        }
        #endif
    }
}
