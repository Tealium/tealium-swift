//
//  TealiumAppDelegateProxy.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//
// Based on  https://notificare.com/blog/2020/07/24/Swizzling-with-Swift/ 🙏

#if os(iOS)
import Foundation
import UIKit

class TealiumAppDelegateProxy: NSProxy {

    private typealias ApplicationOpenURL = @convention(c) (Any, Selector, UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any]) -> Bool
    private typealias ApplicationContinueUserActivity = @convention(c) (Any, Selector, UIApplication, NSUserActivity) -> Void

    private static var contexts: Set<TealiumContext>?

    private struct AssociatedObjectKeys {
        static var originalClass = "Tealium_OriginalClass"
        static var originalImplementations = "Tealium_OriginalImplementations"
    }

    private static var gOriginalAppDelegate: UIApplicationDelegate?
    private static var gAppDelegateSubClass: AnyClass?

    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }

    public static func setup(context: TealiumContext?) {
        if let context = context {
            contexts = contexts ?? Set<TealiumContext>()
            TealiumAppDelegateProxy.contexts?.insert(context)
        }
        // Let the property be initialized and run its block.
        _ = runOnce
    }

    public static func tearDown() {
        contexts?.removeAll()
        contexts = nil
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        weak var appDelegate = TealiumAppDelegateProxy.sharedApplication?.delegate
        proxyAppDelegate(appDelegate)
    }()

    private static func proxyAppDelegate(_ appDelegate: UIApplicationDelegate?) {
        guard let appDelegate = appDelegate else {
            log("Original AppDelegate instance was nil")
            return
        }

        gAppDelegateSubClass = createSubClass(from: appDelegate)
        self.reassignAppDelegate()
    }

    private static func reassignAppDelegate() {
        weak var delegate = TealiumAppDelegateProxy.sharedApplication?.delegate
        TealiumAppDelegateProxy.sharedApplication?.delegate = nil
        TealiumAppDelegateProxy.sharedApplication?.delegate = delegate
        gOriginalAppDelegate = delegate
    }

    private static func createSubClass(from originalDelegate: UIApplicationDelegate) -> AnyClass? {
        let originalClass = type(of: originalDelegate)
        let newClassName = "\(originalClass)_\(UUID().uuidString)"

        guard NSClassFromString(newClassName) == nil else {
            return nil
        }

        guard let subClass = objc_allocateClassPair(originalClass, newClassName, 0) else {
            return nil
        }

        self.createMethodImplementations(in: subClass, withOriginalDelegate: originalDelegate)
        self.overrideDescription(in: subClass)

        // Store the original class
        objc_setAssociatedObject(originalDelegate, &AssociatedObjectKeys.originalClass, originalClass, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        guard class_getInstanceSize(originalClass) == class_getInstanceSize(subClass) else {
            return nil
        }

        objc_registerClassPair(subClass)
        if object_setClass(originalDelegate, subClass) != nil {
            log("Successfully created AppDelegate proxy")
        }

        return subClass
    }

    private static func createMethodImplementations(
        in subClass: AnyClass,
        withOriginalDelegate originalDelegate: UIApplicationDelegate
    ) {
        let originalClass = type(of: originalDelegate)
        var originalImplementationsStore: [String: NSValue] = [:]

        let applicationWillOpenURL = #selector(application(_:openURL:options:))
        self.proxyInstanceMethod(
            toClass: subClass,
            withSelector: applicationWillOpenURL,
            fromClass: TealiumAppDelegateProxy.self,
            fromSelector: applicationWillOpenURL,
            withOriginalClass: originalClass,
            storeOriginalImplementationInto: &originalImplementationsStore)

        let applicationWillContinueUserActivity = #selector(application(_:didUpdateUserActivity:))
        self.proxyInstanceMethod(
            toClass: subClass,
            withSelector: applicationWillContinueUserActivity,
            fromClass: TealiumAppDelegateProxy.self,
            fromSelector: applicationWillContinueUserActivity,
            withOriginalClass: originalClass,
            storeOriginalImplementationInto: &originalImplementationsStore)

        // Store original implementations
        objc_setAssociatedObject(originalDelegate, &AssociatedObjectKeys.originalImplementations, originalImplementationsStore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private static func overrideDescription(in subClass: AnyClass) {
        // Override the description so the custom class name will not show up.
        self.addInstanceMethod(
            toClass: subClass,
            toSelector: #selector(description),
            fromClass: TealiumAppDelegateProxy.self,
            fromSelector: #selector(originalDescription))
    }

    // swiftlint:disable function_parameter_count
    private static func proxyInstanceMethod(
        toClass destinationClass: AnyClass,
        withSelector destinationSelector: Selector,
        fromClass sourceClass: AnyClass,
        fromSelector sourceSelector: Selector,
        withOriginalClass originalClass: AnyClass,
        storeOriginalImplementationInto originalImplementationsStore: inout [String: NSValue]
    ) {
        self.addInstanceMethod(
            toClass: destinationClass,
            toSelector: destinationSelector,
            fromClass: sourceClass,
            fromSelector: sourceSelector)

        let sourceImplementation = methodImplementation(for: destinationSelector, from: originalClass)
        let sourceImplementationPointer = NSValue(pointer: UnsafePointer(sourceImplementation))

        let destinationSelectorStr = NSStringFromSelector(destinationSelector)
        originalImplementationsStore[destinationSelectorStr] = sourceImplementationPointer
    }
    // swiftlint:enable function_parameter_count

    private static func addInstanceMethod(
        toClass destinationClass: AnyClass,
        toSelector destinationSelector: Selector,
        fromClass sourceClass: AnyClass,
        fromSelector sourceSelector: Selector
    ) {
        let method = class_getInstanceMethod(sourceClass, sourceSelector)!
        let methodImplementation = method_getImplementation(method)
        let methodTypeEncoding = method_getTypeEncoding(method)

        if !class_addMethod(destinationClass, destinationSelector, methodImplementation, methodTypeEncoding) {
            log("Cannot copy method to destination selector '\(destinationSelector)' as it already exists.")
        }
    }

    private static func methodImplementation(for selector: Selector, from fromClass: AnyClass) -> IMP? {
        guard let method = class_getInstanceMethod(fromClass, selector) else {
            return nil
        }

        return method_getImplementation(method)
    }

    private static func originalMethodImplementation(for selector: Selector, object: Any) -> NSValue? {
        let originalImplementationsStore = objc_getAssociatedObject(object, &AssociatedObjectKeys.originalImplementations) as? [String: NSValue]
        return originalImplementationsStore?[NSStringFromSelector(selector)]
    }

    /// Handles log messages from the AppDelegate proxy
    /// - Parameter message: `String` containing the message to be logged
    private static func log(_ message: String) {
        let logRequest = TealiumLogRequest(title: "AppDelegateProxy", message: message, info: nil, logLevel: .info, category: .general)
        contexts?.forEach {
            $0.config.logger?.log(logRequest)

        }
    }

    /// Forwards deep link to each registered Tealium instance
    /// - Parameter url: `URL` of the deep link to be handled
    private static func handleDeepLink(_ url: URL) {
        contexts?.forEach {
            $0.handleDeepLink(url)

        }
    }

    @objc
    private func originalDescription() -> String {
        if let originalClass = objc_getAssociatedObject(self, &AssociatedObjectKeys.originalClass) as? AnyClass {
            let originalClassName = NSStringFromClass(originalClass)
            let pointerHex = String(format: "%p", unsafeBitCast(self, to: Int.self))

            return "<\(originalClassName): \(pointerHex)>"
        }
        return "AppDelegate"
    }

    @objc
    private func application(_ app: UIApplication, openURL url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        TealiumAppDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
        TealiumAppDelegateProxy.handleDeepLink(url)
        let methodSelector = #selector(application(_:openURL:options:))
        guard let pointer = TealiumAppDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return true
        }

        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationOpenURL.self)
        _ = originalImplementation(self, methodSelector, app, url, options)
        return false
    }

    @objc
    private func application(_ application: UIApplication, didUpdateUserActivity userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            TealiumAppDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
            TealiumAppDelegateProxy.handleDeepLink(url)
        }

        let methodSelector = #selector(application(_:didUpdateUserActivity:))
        guard let pointer = TealiumAppDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return
        }

        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, application, userActivity)
    }
}
#endif
