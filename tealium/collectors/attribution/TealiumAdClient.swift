//
//  TealiumAdClient.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
import iAd

/// Testable replacement for Apple's AdClient.
public protocol TealiumAdClientProtocol {
    static var shared: TealiumAdClientProtocol { get }
    func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void)
}

/// Implements Apple's AdClient to retrieve Apple Search Ads data.
public class TealiumAdClient: TealiumAdClientProtocol {
    let adClient = ADClient.shared()
    public static var shared: TealiumAdClientProtocol = TealiumAdClient()

    private init() {

    }

    public func requestAttributionDetails(_ completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        adClient.requestAttributionDetails(completionHandler)
    }
}
#endif
