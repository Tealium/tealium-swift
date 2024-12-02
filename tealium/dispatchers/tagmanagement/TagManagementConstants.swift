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
}

enum TagManagementError: TealiumErrorEnum {
    case couldNotCreateURL
    case couldNotLoadURL
    case couldNotJSONEncodeData
    case noDataToTrack
    case webViewNotYetReady
    case unknownDispatchError
}

enum WebviewError: TealiumErrorEnum {
    case webviewURLMissing
    case invalidURL
    case webviewNotInitialized
}

enum WebViewState {
    case loadSuccess
    case loadFailure
}
#endif
