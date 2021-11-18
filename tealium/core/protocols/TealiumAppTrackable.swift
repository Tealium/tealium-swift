// 
// TealiumAppTrackable.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if canImport(SwiftUI) && (arch(arm64) || arch(x86_64))
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public extension View {
    func trackingAppOpenUrl() -> some View {
        return self
            // handles all standard deep links and universal links
            .onOpenURL(perform: didOpenUrl(url:))
            // For some reason, if the link is initiated from camera/NFC tag, this is called and onOpenURL is not called 🤷‍♂️
            // https://stackoverflow.com/questions/65150897/swiftui-universal-links-not-working-for-nfc
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                guard let url = activity.webpageURL else {
                    return
                }
                didOpenUrl(url: url)
            }
    }

    private func didOpenUrl(url: URL) {
        TealiumInstanceManager.shared.didOpenUrl(url)
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct TealiumAppTrackable<Content: View>: View {

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    let content: Content

    public var body: some View {
        content.trackingAppOpenUrl()
    }
}
#endif
