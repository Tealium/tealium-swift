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
extension View {
    
    /**
     * Use this View modifier to autotrack a View appearence with the class name of the view passed as parameter.
     *
     * Usually you apply this modifier in the body of the view you want to track and pass self as parameter.
     */
    public func autoTracking<Target: View>(viewSelf: Target) -> some View {
        return autoTracking(viewClass: type(of:viewSelf))
    }
    
    /**
     * Use this View modifier to autotrack a View appearence with the class name of the view passed as parameter.
     *
     * Usually you apply this modifier in the body of the view you want to track and pass the class whose name you want to track
     * (mainly if you don't have access to the object instance)
     */
    public func autoTracking<Target: View>(viewClass: Target.Type) -> some View {
        return autoTracked(name: String(describing: viewClass))
    }
    
    /**
     * Use this View modifier to autotrack a View appearence with a custom name.
     */
    public func autoTracked(name: String) -> some View {
        return self.onAppear {
            AutotrackingModule.autoTrackView(viewName: name)
        }
    }
}

/**
 * Use this class to wrap a view and autoTrack its appearence with either the content class name or a specific viewName.
 *
 * This is just a more verbose way of expressing which view (the whole content) is auto tracked
 * but it is entirely equivalent to the autoTracking/autoTracked view modifiers.
 *
 * If you don't pass a viewName, the class name of the Content will be used as a viewName.
 */
@available (iOS 14.0, tvOS 14.0, macOS 15.0, watchOS 7.0, *)
public struct TealiumViewTrackable<Content: View>: View {

    let viewName: String?
    let content: Content
    
    public init(viewName: String? = nil,
                @ViewBuilder content: () -> Content) {
        self.content = content()
        self.viewName = viewName
    }

    public var body: some View {
        if let name = viewName {
            content.autoTracked(name: name)
        } else {
            content.autoTracking(viewSelf: content)
        }
    }
}
#endif
