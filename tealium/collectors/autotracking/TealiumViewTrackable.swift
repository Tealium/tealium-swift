// 
// TealiumViewTrackable.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#if autotracking
import TealiumCore
#endif

import Foundation
#if canImport(SwiftUI)
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
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
        return autoTracked(constantName: String(describing: viewClass))
    }
    
    /**
     * Use this View modifier to autotrack a View appearence with a custom name.
     *
     * WARNING:
     * Do NOT pass a State variable here as it may go in conflict with onDisappear calls. https://developer.apple.com/forums/thread/655338
     * If you want to pass a State variable, pass the binding value instead, using the overloaded method.
     */
    public func autoTracked(constantName name: String) -> some View {
        return autoTracked(name: name.toGetterBinding())
    }
    
    /**
     * Use this View modifier to autotrack a View appearence with a custom State name.
     *
     * We won't change the Binding value.
     * This method just solves the issue of onAppear being called after onDisappear for state changes.
     * https://developer.apple.com/forums/thread/655338
     */
    public func autoTracked(name: Binding<String>) -> some View {
        return self.onAppear {
            AutotrackingModule.autoTrackView(viewName: name.wrappedValue)
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
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct TealiumViewTrackable<Content: View>: View {

    
    let viewName: Binding<String>?
    let content: Content
    
    /**
     * WARNING:
     * Do NOT call this method with a name coming from a State object as it may go in conflict with onDisappear calls. https://developer.apple.com/forums/thread/655338
     * If you want to pass a State variable, pass the binding value instead, using the overloaded method.
     */
    public init(constantName: String,
                @ViewBuilder content: () -> Content) {
        self.init(viewName: constantName.toGetterBinding(), content: content)
    }
    
    public init(viewName: Binding<String>? = nil,
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension String {
    func toGetterBinding() -> Binding<String> {
        Binding<String>(get: { self }, set: { _ in })
    }
}
#endif
