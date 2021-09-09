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

@available (iOS 14.0, tvOS 14.0, macOS 15.0, watchOS 7.0, *)
public struct TealiumViewTrackable<Content: View>: View {
public extension View {
    
    func autoTracking<Target: View>(viewSelf: Target) -> some View {
        return autoTracked(name: String(describing: type(of:viewSelf)))
    }
    
    func autoTracked(name: String) -> some View {
        return self.onAppear {
            AutotrackingModule.autoTrackView(viewName: name)
        }
    }
}

@available (iOS 14.0, tvOS 14.0, macOS 15.0, watchOS 7.0, *)

    public var viewName: String

    public init(viewName: String,
                @ViewBuilder content: () -> Content) {
        self.content = content()
        self.viewName = viewName
    }

    let content: Content

    public var body: some View {
        content.autoTracked(name: viewName)
    }
}
#endif
