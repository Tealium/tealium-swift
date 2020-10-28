//
//  TealiumSKAdAttribution.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
#if attribution
import TealiumCore
#endif

public protocol TealiumSKAdAttributionProtocol {
    func extractConversionInfo(from dispatch: TealiumTrackRequest)
    func registerAdNetwork()
    func updateConversion(value: Int)
}

public struct TealiumSKAdAttribution: TealiumSKAdAttributionProtocol {

    var config: TealiumConfig
    var attributor: Attributable

    public init(config: TealiumConfig,
                attributor: Attributable = Attributor()) {
        self.config = config
        self.attributor = attributor
    }

    public func extractConversionInfo(from dispatch: TealiumTrackRequest) {
        guard let event = dispatch.extractKey(lookup: config.skAdConversionKeys) else {
            return
        }
        guard let conversionValue = dispatch.extractLookupValue(for: event) as? Int,
              conversionValue > 0 && conversionValue <= 63 else {
            let error = TealiumLogRequest(title: "SKAdNetwork Error",
                                          message: "Conversion value must be of type Int and between 0-63",
                                          info: nil,
                                          logLevel: .error,
                                          category: .general)
            config.logger?.log(error)
            return
        }
        updateConversion(value: conversionValue)
    }

    public func registerAdNetwork() {
        if #available(iOS 11.3, *) {
            type(of: attributor).self.registerAppForAdNetworkAttribution()
        } else {
            let debug = TealiumLogRequest(title: "SKAdNetwork not available",
                                          message: "11.3 or higher required to use this method",
                                          info: nil,
                                          logLevel: .debug,
                                          category: .general)
            config.logger?.log(debug)
        }
    }

    public func updateConversion(value: Int) {
        if #available(iOS 14.0, *) {
            type(of: attributor).self.updateConversionValue(value)
        } else {
            let debug = TealiumLogRequest(title: "SKAdNetwork.updateConversionValue() not available",
                                          message: "14.0 or higher required to use this method",
                                          info: nil,
                                          logLevel: .debug,
                                          category: .general)
            config.logger?.log(debug)
        }
    }

}
#endif
