// 
// TealiumViewTrackable.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore
#if canImport(SwiftUI)
import SwiftUI
#endif


@available(iOS 13.0, *)
public struct TealiumViewTrackable<Content: View>: View {

    public var viewName: String

    public init(viewName: String,
                @ViewBuilder content: () -> Content) {
        self.content = content()
        self.viewName = viewName
    }

    let content: Content

    public var body: some View {
        content
        .onAppear {
            TealiumInstanceManager.shared.autoTrackView(viewName: viewName)
        }
    }
}
