//
//  WKWebViewAttachToView.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import UIKit

extension TagManagementWKWebView {

    #if os(iOS)
    private var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    /// Attaches the webview to the current UIView (required to ensure proper operation of JavaScript operations).
    ///
    /// - Parameters:
    ///     - specificView: `UIView?` instance to use
    ///     - completion: Completion block to be called when webview was successfully attached to the UIView
    func attachToUIView(specificView: UIView?,
                        withCompletion completion: (_ success: Bool) -> Void) {
        // attach to specific view passed from config override
        if specificView != nil {
            view = specificView
        } else if let application = self.sharedApplication, // auto-detect root view if no view passed in
                  let window = application.keyWindow {
            // view has not already been set or has no window
            if view?.window == nil {
                // set the current view to the current keyWindow
                view = window
            }
        }

        // add webview as subview to whichever view is currently in the view hierarchy
        guard let view = view, let webview = self.webview else {
            // something went wrong; module should error
            completion(false)
            return
        }

        view.addSubview(webview)
        completion(true)
    }
}
#endif
