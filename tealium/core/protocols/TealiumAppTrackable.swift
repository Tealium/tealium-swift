// 
// TealiumAppTrackable.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI

@available (iOS 14.0, *)
public struct TealiumAppTrackable<Content: View>: View {

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    let content: Content

    public var body: some View {
        content
        // handles all standard deep links and universal links
        .onOpenURL(perform: { url in
            postNotification(url: url)
        })
        // For some reason, if the link is initiated from camera/NFC tag, this is called and onOpenURL is not called 🤷‍♂️
        // https://stackoverflow.com/questions/65150897/swiftui-universal-links-not-working-for-nfc
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb, perform: { activity in
            guard let url = activity.webpageURL else {
                return
            }
            postNotification(url: url)
        })
    }
    
    private func postNotification(url: URL) {
        let notification = Notification(name: Notification.Name(rawValue: TealiumValue.deepLinkNotificationName),
                                        object: nil,
                                        userInfo: [TealiumKey.deepLinkURL: url])
        NotificationCenter.default.post(notification)
    }
}
#endif
