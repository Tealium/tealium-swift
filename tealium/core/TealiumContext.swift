//
//  TealiumContext.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumContextProtocol {
    var config: TealiumConfig { get }
    func track(_ dispatch: TealiumDispatch)
}

public struct TealiumContext: Hashable, TealiumContextProtocol {
    public static func == (lhs: TealiumContext, rhs: TealiumContext) -> Bool {
        lhs.config == rhs.config
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(config)
    }

    public unowned var config: TealiumConfig
    public weak var dataLayer: DataLayerManagerProtocol?
    fileprivate weak var tealium: Tealium?
    public var onVisitorId: TealiumObservable<String>? {
        return tealium?.appDataModule?.onVisitorId
    }
    public let sharedState = SharedState()

    public init(config: TealiumConfig,
                dataLayer: DataLayerManagerProtocol,
                tealium: Tealium) {
        self.config = config
        self.dataLayer = dataLayer
        self.tealium = tealium
    }

    public func track(_ dispatch: TealiumDispatch) {
        self.tealium?.track(dispatch)
    }

    public func log(_ logRequest: TealiumLogRequest) {
        self.config.logger?.log(logRequest)
    }

    public func handleDeepLink(_ url: URL, referrer: Tealium.DeepLinkReferrer? = nil) {
        self.tealium?.handleDeepLink(url, referrer: referrer)
    }

}

public class SharedState: NSObject {

    @objc dynamic public var additionalQueryParams: [URLQueryItem] = []

    public func observe<Value>(_ keyPath: KeyPath<SharedState, Value>, options: NSKeyValueObservingOptions = .new, changeHandler: @escaping (Value) -> Void) -> NSKeyValueObservation {
        observe(keyPath, options: options) { _, change in
            guard let value = change.newValue else { return }
            changeHandler(value)
        }
    }
}
