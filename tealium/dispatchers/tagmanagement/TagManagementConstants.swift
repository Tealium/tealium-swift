//
//  TagManagementConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

#if tagmanagement
import TealiumCore
#endif

public extension TealiumDataKey {
    static let jsCommand = "js_command"
    static let jsResult = "js_result"
    static let jsError = "js_error"
    static let responseHeader = "response_headers"
    static let payload = "payload"
}

enum TagManagementKey {
    static let moduleName = "tagmanagement"
    static let defaultUrlStringPrefix = "https://tags.tiqcdn.com/utag"
}

enum TagManagementError: String, LocalizedError {
    case couldNotCreateURL
    case couldNotLoadURL
    case couldNotJSONEncodeData
    case noDataToTrack
    case webViewNotYetReady
    case unknownDispatchError

    public var errorDescription: String? {
        return self.rawValue
    }
}

enum WebviewError: String, LocalizedError {
    case webviewURLMissing
    case invalidURL
    case webviewNotInitialized

    public var errorDescription: String? {
        return self.rawValue
    }
}

enum WebViewState {
    case loadSuccess
    case loadFailure
}
#endif
