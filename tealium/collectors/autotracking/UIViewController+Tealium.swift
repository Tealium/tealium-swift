// 
// UIViewController+Tealium.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TealiumCore

@objc extension UIViewController {

    private typealias ViewDidAppear = @convention(c) (Bool) -> Void

    private static let cls: AnyClass = UIViewController.self

    @objc static func setUp() {
//        TealiumQueues.mainQueue.async {
            _ = runOnce
//        }
    }

    @nonobjc private static let runOnce: () = {
        let originalMethodSelector = #selector(viewDidAppear(_:))
        let originalMethod = class_getInstanceMethod(cls, originalMethodSelector)
        let newMethodSelector = #selector(tealiumViewDidAppear(_:))

        if let newMethod = class_getInstanceMethod(cls, newMethodSelector) {
            let imp = method_getImplementation(newMethod)
            if let originalMethod = originalMethod {
                if (!class_addMethod(cls, originalMethodSelector, imp, method_getTypeEncoding(originalMethod))) {
                        method_setImplementation(originalMethod, imp)
                }
            } else {
               _ = class_addMethod(cls, originalMethodSelector, imp, method_getTypeEncoding(newMethod))
            }
        }
    }()

    @objc func tealiumViewDidAppear(_ animated: Bool) {
        // Avoid double-tracking if this is a TealiumViewController already
        if let superclass = self.superclass,
           String(describing: superclass) == "TealiumViewController" {
                return
        }
        
        print("TealiumViewDidAppear: \(viewTitle)")

        let cls = type(of: self)

        if #available(iOS 13.0, *) {
            var anyClass: AnyClass = UIHostingController<AnyView>.self
            if let vi = class_getInstanceVariable(anyClass, "rootView") {
                print("RootView: \(vi.debugDescription)")
            }
        } else {
            // Fallback on earlier versions
        }


        if #available(iOS 13.0, *) {
            switch self {
            case let sel as UINavigationController:
                print("Navigation")


            default:
                print("default")

            }
        } else {
            // Fallback on earlier versions
        }
    }

}
