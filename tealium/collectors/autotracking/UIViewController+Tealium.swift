// 
// UIViewController+Tealium.swift
// tealium-swift
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

#if os(iOS)
#if autotracking
import TealiumCore
#endif

import Foundation
import UIKit

@objc extension UIViewController {
    
    var viewTitle: String {
        return self.title ?? String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    }
    
    private typealias ViewDidAppear = @convention(c) (Bool) -> Void

    private static let cls: AnyClass = UIViewController.self

    
    fileprivate static var isAutotrackingEnabled: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "TealiumAutotrackingViewControllersEnabled") as? Bool ?? true
    }
    
    @objc static func setUp() {
        TealiumQueues.secureMainThreadExecution {
            _ = runOnce
        }
    }

    @nonobjc private static let runOnce: () = {
        guard isAutotrackingEnabled else {
            return
        }
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
        
        let cls = String(reflecting: type(of: self))
        switch cls {
        case let x where x.contains("SwiftUI."):
                break
        case let x where x.contains("UIInputWindowController"):
                break
        default:
            if getSuperclasses(cls: self) == "" {
                break
            }
            AutotrackingModule.autoTrackView(viewName: viewTitle)
        }
    }
    
    func getSuperclasses(cls: AnyObject) -> String {
        var str = ""
        let separatorToken = " >> "
        var cls = cls
        while let supercls = cls.superclass, let value = supercls {
            str += String(describing: cls) + separatorToken
            cls = value
        }
        str.removeLast(separatorToken.count)
        return str
    }


}
#endif
