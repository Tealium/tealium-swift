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
        .onOpenURL(perform: { url in
            let notification = Notification(name: Notification.Name(rawValue: TealiumValue.deepLinkNotificationName),
                                            object: nil,
                                            userInfo: [TealiumKey.deepLinkURL: url])
            NotificationCenter.default.post(notification)
        })
    }
}
#endif
