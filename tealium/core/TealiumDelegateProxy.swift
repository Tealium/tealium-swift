//
//  TealiumDelegateProxy.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//
// Based on  https://notificare.com/blog/2020/07/24/Swizzling-with-Swift/ 🙏

#if os(iOS)
import Foundation
import UIKit

@available(iOS 13.0, *)
extension UIScene {
    
    static let classInit: Void = {
        swizzleDelegateGetter()
    }()
    
    @objc private var swizzled_delegate: UISceneDelegate? {
        get {
            if let delegate = self.swizzled_delegate {
                TealiumDelegateProxy.sceneEnabled = true
                TealiumDelegateProxy.name = "SceneDelegate"
                TealiumDelegateProxy.proxyUIDelegate(delegate)
            } else {
                TealiumDelegateProxy.proxyUIDelegate(TealiumDelegateProxy.sharedApplication?.delegate)
            }
            return self.swizzled_delegate
        }
    }
    
    private static func swizzleDelegateGetter() {
        let originalSelector = #selector(getter: delegate)
        let swizzledSelector = #selector(getter: swizzled_delegate)
        swizzling(UIScene.self, originalSelector, swizzledSelector)
    }
}



@objc public class TealiumDelegateProxy: NSProxy {

    private typealias ApplicationOpenURL = @convention(c) (Any, Selector, UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any]) -> Bool
    private typealias ApplicationContinueUserActivity = @convention(c) (Any, Selector, UIApplication, NSUserActivity, @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    @available(iOS 13.0, *)
    private typealias SceneWillConnectTo = @convention(c) (Any, Selector, UIScene, UISceneSession, UIScene.ConnectionOptions) -> Void
    @available(iOS 13.0, *)
    private typealias SceneOpenURLContexts = @convention(c) (Any, Selector, UIScene, Set<UIOpenURLContext>) -> Void
    @available(iOS 13.0, *)
    private typealias SceneContinueUserActivity = @convention(c) (Any, Selector, UIScene, NSUserActivity) -> Void

    private static var contexts: Set<TealiumContext>?

    private struct AssociatedObjectKeys {
        static var originalClass = "Tealium_OriginalClass"
        static var originalImplementations = "Tealium_OriginalImplementations"
    }

    fileprivate static var sceneEnabled = false
    fileprivate static var name = "AppDelegate"
    private static var gOriginalDelegate: NSObjectProtocol?
    private static var gDelegateSubClass: AnyClass?

    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }

    @objc public static func setup() {
        setup(context: nil)
    }
    
    public static func setup(context: TealiumContext?) {
        if let context = context {
            contexts = contexts ?? Set<TealiumContext>()
            TealiumDelegateProxy.contexts?.insert(context)
        }
        TealiumQueues.secureMainThreadExecution {
            _ = runOnce
        }
    }

    public static func tearDown() {
        contexts?.removeAll()
        contexts = nil
    }
    
    fileprivate static var isAutotrackingDeepLinkEnabled: Bool {
        return Bundle.main.object(forInfoDictionaryKey: "TealiumAutotrackingDeepLinkEnabled") as? Bool ?? true
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        guard isAutotrackingDeepLinkEnabled else {
            return
        }
        if #available(iOS 13.0, *) {
            _ = UIScene.classInit
        } else {
            let appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
            proxyUIDelegate(appDelegate)
        }
//        if #available(iOS 13.0, *) {
//            getSceneDelegate { sceneDelegate in
//                let delegate: NSObjectProtocol?
//                if let sceneDelegate = sceneDelegate {
//                    TealiumDelegateProxy.name = "SceneDelegate"
//                    sceneEnabled = true
//                    delegate = sceneDelegate
//                } else {
//                    delegate = TealiumDelegateProxy.sharedApplication?.delegate
//                }
//                proxyUIDelegate(delegate)
//            }
//        } else {
//            let appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
//            proxyUIDelegate(appDelegate)
//        }
    }()
    
    @available(iOS 13.0, *)
    static private func getSceneDelegate(completion: @escaping (UISceneDelegate?) -> ()) {
        if TealiumDelegateProxy.sharedApplication?.applicationState == .active {
            completion(TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate)
            return
        }
        var observer: NSObjectProtocol?
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            weak var sceneDelegate = TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate
            completion(sceneDelegate)
            guard let observer = observer else {
                return
            }
            NotificationCenter.default.removeObserver(observer, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }

    fileprivate static func proxyUIDelegate(_ uiDelegate: NSObjectProtocol?) {
        guard let uiDelegate = uiDelegate, gDelegateSubClass == nil else {
            log("Original \(TealiumDelegateProxy.name) instance was nil")
            return
        }

        gDelegateSubClass = createSubClass(from: uiDelegate)
        self.reassignDelegate()
    }

    private static func reassignDelegate() { // is this useful?
        guard sceneEnabled else {
            weak var appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
            TealiumDelegateProxy.sharedApplication?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.delegate = appDelegate
            gOriginalDelegate = appDelegate
            return
        }
        if #available(iOS 13.0, *) {
            weak var sceneDelegate = TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate
            TealiumDelegateProxy.sharedApplication?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate = sceneDelegate
            gOriginalDelegate = sceneDelegate
        }
    }

    private static func createSubClass(from originalDelegate: NSObjectProtocol) -> AnyClass? {
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
            log("Successfully created \(TealiumDelegateProxy.name) proxy")
        }

        return subClass
    }

    private static func createMethodImplementations(
        in subClass: AnyClass,
        withOriginalDelegate originalDelegate: NSObjectProtocol
    ) {
        let originalClass = type(of: originalDelegate)
        var originalImplementationsStore: [String: NSValue] = [:]
        
        if #available(iOS 13.0, *), sceneEnabled {
            let sceneOpenURLContexts = #selector(scene(_:openURLContexts:))
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneOpenURLContexts,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneOpenURLContexts,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            
            let sceneContinueUserActivity = #selector(scene(_:continueUserActivity:))
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            let sceneWillConnectTo = #selector(scene(_:willConnectToSession:options:))
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneWillConnectTo,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneWillConnectTo,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        } else {
            let applicationWillOpenURL = #selector(application(_:openURL:options:))
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationWillOpenURL,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationWillOpenURL,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            
            let applicationWillContinueUserActivity = #selector(application(_:continueUserActivity:restorationHandler:))
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationWillContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationWillContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        }
        
        
        // Store original implementations
        objc_setAssociatedObject(originalDelegate, &AssociatedObjectKeys.originalImplementations, originalImplementationsStore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private static func overrideDescription(in subClass: AnyClass) {
        // Override the description so the custom class name will not show up.
        self.addInstanceMethod(
            toClass: subClass,
            toSelector: #selector(description),
            fromClass: TealiumDelegateProxy.self,
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

    /// Handles log messages from the App or SceneDelegate proxy
    /// - Parameter message: `String` containing the message to be logged
    private static func log(_ message: String) {
        let logRequest = TealiumLogRequest(title: "TealiumDelegateProxy", message: message, info: nil, logLevel: .info, category: .general)
        contexts?.forEach {
            $0.config.logger?.log(logRequest)

        }
    }

    /// Forwards deep link to each registered Tealium instance
    /// - Parameter url: `URL` of the deep link to be handled
    private static func handleDeepLink(_ url: URL, referrer: Tealium.DeepLinkReferrer? = nil) {
        contexts?.forEach {
            $0.handleDeepLink(url, referrer: referrer)
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
        TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
        TealiumDelegateProxy.handleDeepLink(url, referrer: .fromAppId(options[.sourceApplication] as? String))
        let methodSelector = #selector(application(_:openURL:options:))
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return true
        }

        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationOpenURL.self)
        _ = originalImplementation(self, methodSelector, app, url, options)
        return false
    }

    @objc
    private func application(_ application: UIApplication,
                             continueUserActivity userActivity: NSUserActivity,
                             restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        handleContinueUserActivity(userActivity)
        
        let methodSelector = #selector(application(_:continueUserActivity:restorationHandler:))
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return true
        }

        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, application, userActivity, restorationHandler)
        return false
    }
    
    @available(iOS 13.0, *)
    @objc
    private func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleUrlContexts(URLContexts)
        let methodSelector = #selector(scene(_:openURLContexts:))
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return
        }

        let originalImplementation = unsafeBitCast(pointerValue, to: SceneOpenURLContexts.self)
        _ = originalImplementation(self, methodSelector, scene, URLContexts)
    }
    
    @available(iOS 13.0, *)
    @objc
    private func scene(_ scene: UIScene, continueUserActivity: NSUserActivity) {
        handleContinueUserActivity(continueUserActivity)
        let methodSelector = #selector(scene(_:continueUserActivity:))
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return
        }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, scene, continueUserActivity)
    }
    
    private func handleContinueUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
            var referrer: Tealium.DeepLinkReferrer?
            if #available(iOS 11.0, *) {
                referrer = .fromUrl(userActivity.referrerURL)
            }
            TealiumDelegateProxy.handleDeepLink(url, referrer: referrer)
        }
    }
    
    @available(iOS 13.0, *)
    private func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) {
        urlContexts.forEach { urlContext in
            TealiumDelegateProxy.log("Received Deep Link: \(urlContext.url.absoluteString)")
            TealiumDelegateProxy.handleDeepLink(urlContext.url, referrer: .fromAppId(urlContext.options.sourceApplication))
        }
    }
    
    @available(iOS 13.0, *)
    @objc
    func scene(_ scene: UIScene, willConnectToSession session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        handleUrlContexts(connectionOptions.urlContexts)
        let methodSelector = #selector(scene(_:willConnectToSession:options:))
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
            return
        }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneWillConnectTo.self)
        _ = originalImplementation(self, methodSelector, scene, session, connectionOptions)
    }
    
}
#endif
