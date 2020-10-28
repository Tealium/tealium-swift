//
//  DeviceDataScreenInfo.swift
//  tealium-swift
//
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

// MARK: Screen Info
public extension DeviceData {
    /// - Returns: `String` containing the device's resolution
    class var resolution: String {
        #if os(OSX)
        return TealiumValue.unknown
        #elseif os(watchOS)
        let res = WKInterfaceDevice.current().screenBounds
        let scale = WKInterfaceDevice.current().screenScale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", height, width)
        return stringRes
        #else
        let res = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let width = res.width * scale
        let height = res.height * scale
        let stringRes = String(format: "%.0fx%.0f", height, width)
        return stringRes
        #endif
    }

    /// - Returns: `[String: Stirng]` containing the device's physical and UI orientation
    var orientation: [String: String] {
        // UIDevice.current.orientation is available on iOS only
        #if os(iOS)
        let orientation = UIDevice.current.orientation

        let isLandscape = orientation.isLandscape
        var fullOrientation = [DeviceDataKey.orientation: isLandscape ? "Landscape" : "Portrait"]

        fullOrientation[DeviceDataKey.fullOrientation] = getDeviceOrientation(orientation)
        return fullOrientation
        #else
        return [DeviceDataKey.orientation: TealiumValue.unknown,
                DeviceDataKey.fullOrientation: TealiumValue.unknown
        ]
        #endif
    }

    #if os(iOS)
    /// - Returns: `String` containing the device's UI orientation
    internal func getUIOrientation(_ orientation: UIInterfaceOrientation) -> String {
        var appOrientationString: String
        switch orientation {
        case .landscapeLeft:
            appOrientationString = "Landscape Left"
        case .landscapeRight:
            appOrientationString = "Landscape Right"
        case .portrait:
            appOrientationString = "Portrait"
        case .portraitUpsideDown:
            appOrientationString = "Portrait Upside Down"
        case .unknown:
            appOrientationString = TealiumValue.unknown
        @unknown default:
            appOrientationString = TealiumValue.unknown
        }
        return appOrientationString
    }

    /// - Returns: `String` containing the device's physical orientation
    internal func getDeviceOrientation(_ orientation: UIDeviceOrientation) -> String {
        var deviceOrientationString: String
        switch orientation {
        case .faceUp:
            deviceOrientationString = "Face Up"
        case .faceDown:
            deviceOrientationString = "Face Down"
        case .landscapeLeft:
            deviceOrientationString = "Landscape Left"
        case .landscapeRight:
            deviceOrientationString = "Landscape Right"
        case .portrait:
            deviceOrientationString = "Portrait"
        case .portraitUpsideDown:
            deviceOrientationString = "Portrait Upside Down"
        case .unknown:
            deviceOrientationString = TealiumValue.unknown
        @unknown default:
            deviceOrientationString = TealiumValue.unknown
        }
        return deviceOrientationString
    }
    #endif
}
