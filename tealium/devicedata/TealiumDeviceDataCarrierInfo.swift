//
//  TealiumDeviceDataCarrierInfo.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(tvOS)
#elseif os(watchOS)
#else
import CoreTelephony
#endif
import Foundation

extension TealiumDeviceData {
    /// - Returns: `[String: String]` containing current network carrier info
    class func carrierInfo() -> [String: String] {
        // only available on iOS
        var carrierInfo: [String: String]
        // avoiding direct assignment to suppress spurious compiler warning (never mutated)
        carrierInfo = [String: String]()
        #if os(iOS)
        // beginning in iOS 12, Xcode generates lots of errors
        // when calling CTTelephonyNetworkInfo from the simulator
        // this is a workaround
        #if targetEnvironment(simulator)
        carrierInfo = [
            TealiumDeviceDataKey.carrierMNC: "00",
            TealiumDeviceDataKey.carrierMCC: "000",
            TealiumDeviceDataKey.carrierISO: "us",
            TealiumDeviceDataKey.carrier: "simulator",
            TealiumDeviceDataKey.carrierMNCLegacy: "00",
            TealiumDeviceDataKey.carrierMCCLegacy: "000",
            TealiumDeviceDataKey.carrierISOLegacy: "us",
            TealiumDeviceDataKey.carrierLegacy: "simulator",
        ]
        #else
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        if #available(iOS 12.1, *) {
            if let newCarrier = networkInfo.serviceSubscriberCellularProviders {
                // pick up the first carrier in the list
                for currentCarrier in newCarrier {
                    carrier = currentCarrier.value
                    break
                }
            }
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        carrierInfo = [
            TealiumDeviceDataKey.carrierMNCLegacy: carrier?.mobileNetworkCode ?? "",
            TealiumDeviceDataKey.carrierMNC: carrier?.mobileNetworkCode ?? "",
            TealiumDeviceDataKey.carrierMCCLegacy: carrier?.mobileCountryCode ?? "",
            TealiumDeviceDataKey.carrierMCC: carrier?.mobileCountryCode ?? "",
            TealiumDeviceDataKey.carrierISOLegacy: carrier?.isoCountryCode ?? "",
            TealiumDeviceDataKey.carrierISO: carrier?.isoCountryCode ?? "",
            TealiumDeviceDataKey.carrierLegacy: carrier?.carrierName ?? "",
            TealiumDeviceDataKey.carrier: carrier?.carrierName ?? "",
        ]
        #endif
        #endif
        return carrierInfo
    }
}
