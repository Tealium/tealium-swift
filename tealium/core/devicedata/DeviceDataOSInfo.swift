//
//  DeviceDataOSInfo.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(OSX)
#else
import UIKit
#endif
import Foundation

#if os(watchOS)
import WatchKit
#endif

// MARK: OS Info
public extension DeviceData {
    class var oSBuild: String {
        guard let build = Bundle.main.infoDictionary?["DTSDKBuild"] as? String else {
            return DeviceDataValue.unknown
        }
        return build

    }

    class var oSVersion: String {
        // only available on iOS and tvOS
        #if os(iOS)
        return UIDevice.current.systemVersion
        #elseif os(tvOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(OSX)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return DeviceDataValue.unknown
        #endif
    }

    class var oSName: String {
        // only available on iOS and tvOS
        #if os(iOS)
        return UIDevice.current.systemName
        #elseif os(tvOS)
        return UIDevice.current.systemName
        #elseif os(OSX)
        return "macOS"
        #else
        return DeviceDataValue.unknown
        #endif
    }
}
