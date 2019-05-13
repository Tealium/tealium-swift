//
//  TealiumTagManagementConstants.swift
//  tealium-swift
//
//  Created by Craig Rouse on 07/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

enum TealiumTagManagementKey {
    static let jsCommand = "js_command"
    static let jsResult = "js_result"
    static let jsError = "js_error"
    static let moduleName = "tagmanagement"
    static let responseHeader = "response_headers"
    static let payload = "payload"
    static let defaultUrlStringPrefix = "https://tags.tiqcdn.com/utag"
}

enum TealiumTagManagementConfigKey {
    static let disable = "disable_tag_management"
    static let maxQueueSize = "tagmanagement_queue_size"
    static let overrideURL = "tagmanagement_override_url"
    static let delegate = "delegate"
    static let shouldUseLegacyWebview = "use_legacy_webview"
    static let uiview = "ui_view"
}

enum TealiumTagManagementValue {
    static let defaultQueueSize = 100
}

enum TealiumTagManagementError: Error {
    case couldNotCreateURL
    case couldNotLoadURL
    case couldNotJSONEncodeData
    case noDataToTrack
    case webViewNotYetReady
    case unknownDispatchError
}

enum TealiumTagManagementNotificationKey {
    static let urlRequestMade = "com.tealium.tagmanagement.urlrequest"
    static let jsCommand = "js"
}

public enum TealiumWebviewError: Error {
    case webviewURLMissing
    case invalidURL
    case webviewNotInitialized
}

public enum TealiumWebViewState {
    case loadSuccess
    case loadFailure
}
