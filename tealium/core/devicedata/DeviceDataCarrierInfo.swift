//
//  DeviceDataCarrierInfo.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(tvOS)
#elseif os(watchOS)
#else
import CoreTelephony
#endif
import Foundation

extension DeviceData {
    /// - Returns: `[String: String]` containing current network carrier info
    class var carrierInfo: [String: String] {
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
            DeviceDataKey.carrierMNC: "00",
            DeviceDataKey.carrierMCC: "000",
            DeviceDataKey.carrierISO: "us",
            DeviceDataKey.carrier: "simulator"
        ]
        #elseif targetEnvironment(macCatalyst)
        carrierInfo = [
            DeviceDataKey.carrierMNC: "00",
            DeviceDataKey.carrierMCC: "000",
            DeviceDataKey.carrierISO: "us",
            DeviceDataKey.carrier: "macCatalyst"
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
            DeviceDataKey.carrierMNC: carrier?.mobileNetworkCode ?? "",
            DeviceDataKey.carrierMCC: carrier?.mobileCountryCode ?? "",
            DeviceDataKey.carrierISO: carrier?.isoCountryCode ?? "",
            DeviceDataKey.carrier: carrier?.carrierName ?? ""
        ]
        #endif
        #endif
        return carrierInfo
    }
}
