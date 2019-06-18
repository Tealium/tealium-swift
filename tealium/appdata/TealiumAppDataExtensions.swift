//
//  TealiumAppDataExtensions.swift
//  tealium-swift
//
//  Created by Craig Rouse on 3/14/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumAppDataCollection {

    /// Retrieves app name from Bundle
    ///
    /// - Parameter bundle: Bundle
    /// - Returns: String? containing the app name
    func name(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    /// Retrieves the rdns package identifier from Bundle
    ///
    /// - Parameter bundle: Bundle
    /// - Returns: String? containing the rdns package identifier
    func rdns(bundle: Bundle) -> String? {
        return bundle.bundleIdentifier
    }

    /// Retrieves app version from Bundle
    ///
    /// - Parameter bundle: Bundle
    /// - Returns: String? containing the app version
    func version(bundle: Bundle) -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Retrieves app build number from Bundle
    ///
    /// - Parameter bundle: Bundle
    /// - Returns: String? containing the app build number
    func build(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}
