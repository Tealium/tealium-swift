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

@objc public class TealiumDelegateProxy: NSProxy {
    
    static var contexts: Set<TealiumContext>?
    
    private struct AssociatedObjectKeys {
        static var originalClass = "Tealium_OriginalClass"
        static var originalImplementations = "Tealium_OriginalImplementations"
    }
    
    static private(set) var sceneEnabled = false
    private static var name = "AppDelegate"
    
    @objc public static func setup() {
        setup(context: nil)
    }
    
    public static func setup(context: TealiumContext?) {
        guard isAutotrackingDeepLinkEnabled else {
            return
        }
        if let context = context {
            contexts = contexts ?? Set<TealiumContext>()
            TealiumDelegateProxy.contexts?.insert(context)
        }
        TealiumQueues.secureMainThreadExecution {
            _ = runOnce
        }
    }
    
    public static func removeContext(_ context: TealiumContext?) {
        guard isAutotrackingDeepLinkEnabled else {
            return
        }
        if let context = context, contexts?.contains(context) == true {
            contexts?.remove(context)
        }
    }
    
    private static let isAutotrackingDeepLinkEnabled: Bool = {
        return Bundle.main.object(forInfoDictionaryKey: "TealiumAutotrackingDeepLinkEnabled") as? Bool ?? true
    }()
    
    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        guard isAutotrackingDeepLinkEnabled else {
            return
        }
        if #available(iOS 13.0, *) {
            UIScene.onDelegateGetterBlock = { delegate in
                UIScene.onDelegateGetterBlock = nil
                if let delegate = delegate {
                    TealiumDelegateProxy.proxySceneDelegate(delegate)
                } else {
                    TealiumDelegateProxy.proxyAppDelegate()
                }
            }
            _ = UIScene.tealSwizzleDelegateGetterOnce
        } else {
            proxyAppDelegate()
        }
    }()
}

// MARK: Swizzling

private extension TealiumDelegateProxy {
    
    typealias ApplicationOpenURL = @convention(c) (Any, Selector, UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any]) -> Bool
    typealias ApplicationContinueUserActivity = @convention(c) (Any, Selector, UIApplication, NSUserActivity, @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    @available(iOS 13.0, *)
    typealias SceneWillConnectTo = @convention(c) (Any, Selector, UIScene, UISceneSession, UIScene.ConnectionOptions) -> Void
    @available(iOS 13.0, *)
    typealias SceneOpenURLContexts = @convention(c) (Any, Selector, UIScene, Set<UIOpenURLContext>) -> Void
    @available(iOS 13.0, *)
    typealias SceneContinueUserActivity = @convention(c) (Any, Selector, UIScene, NSUserActivity) -> Void
    
    static let ApplicationOperUrlSelector = #selector(application(_:openURL:options:))
    static let ApplicationContinueUserActivitySelector = #selector(application(_:continueUserActivity:restorationHandler:))
    @available(iOS 13.0, *)
    static let SceneWillConnectToSelector = #selector(scene(_:willConnectToSession:options:))
    @available(iOS 13.0, *)
    static let SceneOpenURLContextsSelector = #selector(scene(_:openURLContexts:))
    @available(iOS 13.0, *)
    static let SceneContinueUserActivitySelector = #selector(scene(_:continueUserActivity:))
    
    static var gOriginalDelegate: NSObjectProtocol?
    static var gDelegateSubClass: AnyClass?
    
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
    
    @available(iOS 13.0, *)
    static func proxySceneDelegate(_ sceneDelegate: UISceneDelegate) {
        sceneEnabled = true
        name = "SceneDelegate"
        proxyUIDelegate(sceneDelegate)
    }
    
    static func proxyAppDelegate() {
        let appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
        proxyUIDelegate(appDelegate)
    }
    
    static func proxyUIDelegate(_ uiDelegate: NSObjectProtocol?) {
        guard let uiDelegate = uiDelegate, gDelegateSubClass == nil else {
            log("Original \(TealiumDelegateProxy.name) instance was nil")
            return
        }
        
        gDelegateSubClass = createSubClass(from: uiDelegate)
        self.reassignDelegate()
    }
    
    // This is required otherwise if AppDelegate/SceneDelegate don't implement those methods it won't work!
    // Setting the delegate again probably causes the system to check again for the presence of those methods that were missing before.
    static func reassignDelegate() {
        if #available(iOS 13.0, *), sceneEnabled {
            weak var sceneDelegate = TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate
            TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.connectedScenes.first?.delegate = sceneDelegate
            gOriginalDelegate = sceneDelegate
        } else {
            weak var appDelegate = TealiumDelegateProxy.sharedApplication?.delegate
            TealiumDelegateProxy.sharedApplication?.delegate = nil
            TealiumDelegateProxy.sharedApplication?.delegate = appDelegate
            gOriginalDelegate = appDelegate
        }
    }
    
    static func createSubClass(from originalDelegate: NSObjectProtocol) -> AnyClass? {
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
    
    static func createMethodImplementations(
        in subClass: AnyClass,
        withOriginalDelegate originalDelegate: NSObjectProtocol
    ) {
        let originalClass = type(of: originalDelegate)
        var originalImplementationsStore: [String: NSValue] = [:]
        
        if #available(iOS 13.0, *), sceneEnabled {
            let sceneOpenURLContexts = SceneOpenURLContextsSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneOpenURLContexts,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneOpenURLContexts,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            
            let sceneContinueUserActivity = SceneContinueUserActivitySelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            let sceneWillConnectTo = SceneWillConnectToSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: sceneWillConnectTo,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: sceneWillConnectTo,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        } else {
            let applicationOpenURL = ApplicationOperUrlSelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationOpenURL,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationOpenURL,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
            
            let applicationContinueUserActivity = ApplicationContinueUserActivitySelector
            self.proxyInstanceMethod(
                toClass: subClass,
                withSelector: applicationContinueUserActivity,
                fromClass: TealiumDelegateProxy.self,
                fromSelector: applicationContinueUserActivity,
                withOriginalClass: originalClass,
                storeOriginalImplementationInto: &originalImplementationsStore)
        }
        
        // Store original implementations
        objc_setAssociatedObject(originalDelegate, &AssociatedObjectKeys.originalImplementations, originalImplementationsStore, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    static func overrideDescription(in subClass: AnyClass) {
        // Override the description so the custom class name will not show up.
        self.addInstanceMethod(
            toClass: subClass,
            toSelector: #selector(description),
            fromClass: TealiumDelegateProxy.self,
            fromSelector: #selector(originalDescription))
    }
    
    // swiftlint:disable function_parameter_count
    static func proxyInstanceMethod(
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
    
    static func addInstanceMethod(
        toClass destinationClass: AnyClass,
        toSelector destinationSelector: Selector,
        fromClass sourceClass: AnyClass,
        fromSelector sourceSelector: Selector
    ) {
        guard let method = class_getInstanceMethod(sourceClass, sourceSelector) else {
            log("Cannot get instance method")
            return
        }
        let methodImplementation = method_getImplementation(method)
        let methodTypeEncoding = method_getTypeEncoding(method)
        
        if !class_addMethod(destinationClass, destinationSelector, methodImplementation, methodTypeEncoding) {
            log("Cannot copy method to destination selector '\(destinationSelector)' as it already exists.")
        }
    }
    
    static func methodImplementation(for selector: Selector, from fromClass: AnyClass) -> IMP? {
        guard let method = class_getInstanceMethod(fromClass, selector) else {
            return nil
        }
        return method_getImplementation(method)
    }
    
    static func originalMethodImplementation(for selector: Selector, object: Any) -> NSValue? {
        let originalImplementationsStore = objc_getAssociatedObject(object, &AssociatedObjectKeys.originalImplementations) as? [String: NSValue]
        return originalImplementationsStore?[NSStringFromSelector(selector)]
    }
}

// MARK: App Delegate

private extension TealiumDelegateProxy {
    
    @objc
    func application(_ app: UIApplication, openURL url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
        TealiumDelegateProxy.handleDeepLink(url, referrer: .fromAppId(options[.sourceApplication] as? String))
        let methodSelector = TealiumDelegateProxy.ApplicationOperUrlSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return true
              }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationOpenURL.self)
        _ = originalImplementation(self, methodSelector, app, url, options)
        return false
    }
    
    @objc
    func application(_ application: UIApplication,
                     continueUserActivity userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        handleContinueUserActivity(userActivity)
        
        let methodSelector = TealiumDelegateProxy.ApplicationContinueUserActivitySelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return true
              }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: ApplicationContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, application, userActivity, restorationHandler)
        return false
    }
    
    @objc
    func originalDescription() -> String {
        if let originalClass = objc_getAssociatedObject(self, &AssociatedObjectKeys.originalClass) as? AnyClass {
            let originalClassName = NSStringFromClass(originalClass)
            let pointerHex = String(format: "%p", unsafeBitCast(self, to: Int.self))
            
            return "<\(originalClassName): \(pointerHex)>"
        }
        return "AppDelegate"
    }
}

// MARK: Scene Delegate

@available(iOS 13.0, *)
private extension TealiumDelegateProxy {
    
    @objc
    func scene(_ scene: UIScene,
               willConnectToSession session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let activity = connectionOptions.userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb}) {
            handleContinueUserActivity(activity)
        } else {
            handleUrlContexts(connectionOptions.urlContexts)
        }
        let methodSelector = TealiumDelegateProxy.SceneWillConnectToSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneWillConnectTo.self)
        _ = originalImplementation(self, methodSelector, scene, session, connectionOptions)
    }
    
    @objc
    func scene(_ scene: UIScene, continueUserActivity: NSUserActivity) {
        handleContinueUserActivity(continueUserActivity)
        let methodSelector = TealiumDelegateProxy.SceneContinueUserActivitySelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }
        
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneContinueUserActivity.self)
        _ = originalImplementation(self, methodSelector, scene, continueUserActivity)
    }
    
    @objc
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleUrlContexts(URLContexts)
        let methodSelector = TealiumDelegateProxy.SceneOpenURLContextsSelector
        guard let pointer = TealiumDelegateProxy.originalMethodImplementation(for: methodSelector, object: self),
              let pointerValue = pointer.pointerValue else {
                  return
              }
        let originalImplementation = unsafeBitCast(pointerValue, to: SceneOpenURLContexts.self)
        _ = originalImplementation(self, methodSelector, scene, URLContexts)
    }
    
    func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) {
        urlContexts.forEach { urlContext in
            TealiumDelegateProxy.log("Received Deep Link: \(urlContext.url.absoluteString)")
            TealiumDelegateProxy.handleDeepLink(urlContext.url, referrer: .fromAppId(urlContext.options.sourceApplication))
        }
    }
}

// MARK: Utils

private extension TealiumDelegateProxy {
    
    func handleContinueUserActivity(_ userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            TealiumDelegateProxy.log("Received Deep Link: \(url.absoluteString)")
            var referrer: Tealium.DeepLinkReferrer?
            if #available(iOS 11.0, *) {
                referrer = .fromUrl(userActivity.referrerURL)
            }
            TealiumDelegateProxy.handleDeepLink(url, referrer: referrer)
        }
    }
    
    /// Handles log messages from the App or SceneDelegate proxy
    /// - Parameter message: `String` containing the message to be logged
    static func log(_ message: String) {
        let logRequest = TealiumLogRequest(title: "TealiumDelegateProxy", message: message, info: nil, logLevel: .info, category: .general)
        contexts?.forEach {
            $0.config.logger?.log(logRequest)
        }
    }
    
    /// Forwards deep link to each registered Tealium instance
    /// - Parameter url: `URL` of the deep link to be handled
    static func handleDeepLink(_ url: URL, referrer: Tealium.DeepLinkReferrer? = nil) {
        contexts?.forEach {
            $0.handleDeepLink(url, referrer: referrer)
        }
    }
}


#endif
