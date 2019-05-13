//
//  TealiumWKWebViewAttachToView.swift
//  tealium-swift
//
//  Created by Craig Rouse on 13/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 11.0, *)
extension TealiumTagManagementWKWebView {

    #if os(iOS)
    private var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    #endif

    /// Attaches the webview to the current UIView (required to ensure proper operation of JavaScript operations).
    ///
    /// - Parameters:
    /// - specificView: UIView instance to use
    /// - withCompletion: Completion block to be called when webview was successfully attached to the UIView
    func attachToUIView(specificView: UIView?,
                        withCompletion completion: (_ success: Bool) -> Void) {
        // attach to specific view passed from config override
        if specificView != nil {
            view = specificView
        } else if let application = self.sharedApplication, // auto-detect root view if no view passed in
                let window = application.keyWindow,
                let rootViewController = window.rootViewController {

            var topViewController: UIViewController?
            if let navigationController = rootViewController as? UINavigationController {
                topViewController = navigationController.viewControllers.last
            } else if let tabBarController = rootViewController as? UITabBarController {
                topViewController = tabBarController.selectedViewController
            } else {
                topViewController = rootViewController
            }

            // view has not already been set, and the detected top view controller is in the view hierarchy (window is not nil) => this is an auto-detected view
            if view == nil && topViewController?.view.window != nil {
                // set the current view to the auto-detected view
                view = topViewController?.viewIfLoaded
            }
        }

        // add webview as subview to whichever view is currently in the view hierarchy
        if let view = view, let webview = self.webview {
            view.addSubview(webview)
            completion(true)
        } else {
            // something went wrong; module should error
            completion(false)
        }
    }
}
