//
//  TagManagementConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

enum TagManagementKey {
    static let jsCommand = "js_command"
    static let jsResult = "js_result"
    static let jsError = "js_error"
    static let moduleName = "tagmanagement"
    static let responseHeader = "response_headers"
    static let payload = "payload"
    static let defaultUrlStringPrefix = "https://tags.tiqcdn.com/utag"
}

enum TagManagementConfigKey {
    static let disable = "disable_tag_management"
    static let maxQueueSize = "tagmanagement_queue_size"
    static let overrideURL = "tagmanagement_override_url"
    static let delegate = "delegate"
    static let uiview = "ui_view"
    static let cookieObserver = "cookie_observer"
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
