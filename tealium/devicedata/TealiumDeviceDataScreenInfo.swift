//
//  TealiumDeviceDataScreenInfo.swift
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

// MARK: Screen Info
extension TealiumDeviceData {
    /// - Returns: `String` containing the device's resolution
    class func resolution() -> String {
        #if os(OSX)
        return TealiumDeviceDataValue.unknown
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
    public func orientation() -> [String: String] {
        // UIDevice.current.orientation is available on iOS only
        #if os(iOS)
        let orientation = UIDevice.current.orientation
        var appOrientation: UIInterfaceOrientation?

        if !Thread.isMainThread {
            DispatchQueue.main.sync {
                appOrientation = TealiumDeviceData.sharedApplication?.statusBarOrientation
            }
        } else {
            appOrientation = TealiumDeviceData.sharedApplication?.statusBarOrientation
        }

        let isLandscape = orientation.isLandscape
        var fullOrientation = [TealiumDeviceDataKey.orientation: isLandscape ? "Landscape" : "Portrait"]

        fullOrientation[TealiumDeviceDataKey.fullOrientation] = getDeviceOrientation(orientation)
        if let appOrientation = appOrientation {
            let isAppLandscape = appOrientation.isLandscape
            fullOrientation[TealiumDeviceDataKey.appOrientation] = isAppLandscape ? "Landscape" : "Portrait"
            fullOrientation[TealiumDeviceDataKey.appOrientationExtended] = getUIOrientation(appOrientation)
        }
        return fullOrientation
        #else
        return [TealiumDeviceDataKey.orientation: TealiumDeviceDataValue.unknown,
                TealiumDeviceDataKey.fullOrientation: TealiumDeviceDataValue.unknown,
        ]
        #endif
    }

    #if os(iOS)
    /// - Returns: `String` containing the device's UI orientation
    func getUIOrientation(_ orientation: UIInterfaceOrientation) -> String {
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
            appOrientationString = TealiumDeviceDataValue.unknown
        }
        return appOrientationString
    }

    /// - Returns: `String` containing the device's physical orientation
    func getDeviceOrientation(_ orientation: UIDeviceOrientation) -> String {
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
            deviceOrientationString = TealiumDeviceDataValue.unknown
        }
        return deviceOrientationString
    }
    #endif
}
