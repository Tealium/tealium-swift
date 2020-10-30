//
//  TealiumMessageHandler.swift
//  SwiftUIWebView
//
//  Copyright © 2020 Tealium. All rights reserved.
//

import Foundation
import WebKit

extension WebView.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        guard let body = message.body as? [String: Any],
              let command = body[Constants.command] as? String,
              let title = body[Constants.title] as? String,
              let webViewData = body[Constants.data] as? [String: Any] else {
            return
        }

        let trackPayload = filterPrefixes(from: webViewData)

        switch command {
        case Constants.track:
            print("tealium track called: \(trackPayload)")
            TealiumHelper.trackEvent(title: title, dataLayer: trackPayload)
        case Constants.trackView:
            print("tealium trackView called: \(trackPayload)")
            TealiumHelper.trackView(title: title, dataLayer: trackPayload)
        default:
            break
        }
    }

    // Only needed if track coming from utag.js and it is desired to filter out these variables
    private func filterPrefixes(from dictionary: [String: Any]) -> [String: Any] {
        dictionary.filter {
            !$0.key.hasPrefix("tealium_") &&
                !$0.key.hasPrefix("cp.") &&
                !$0.key.hasPrefix("dom.") &&
                !$0.key.hasPrefix("ut.") &&
                !$0.key.hasPrefix("va.") &&
                !$0.key.hasPrefix("qp.") &&
                !$0.key.hasPrefix("js_page.")
        }
    }

}

private enum Constants {
    static let track = "track"
    static let trackView = "trackView"
    static let command = "command"
    static let title = "title"
    static let data = "data"
    static let account = "ut.account"
    static let profile = "ut.profile"
    static let env = "ut.env"
    static let fromNative = "from_sdk"
}

extension TealiumHelper {
    var webViewType: WebUrlType {
        exampleType == .noUtag ? .localUrl : .publicUrl
    }
}
