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

    #if os(iOS) && !targetEnvironment(macCatalyst)
    private static let networkInfo = CTTelephonyNetworkInfo()
    #endif

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
            TealiumDataKey.carrierMNC: "00",
            TealiumDataKey.carrierMCC: "000",
            TealiumDataKey.carrierISO: "us",
            TealiumDataKey.carrier: "simulator"
        ]
        #elseif targetEnvironment(macCatalyst)
        carrierInfo = [
            TealiumDataKey.carrierMNC: "00",
            TealiumDataKey.carrierMCC: "000",
            TealiumDataKey.carrierISO: "us",
            TealiumDataKey.carrier: "macCatalyst"
        ]
        #else
        var carrier: CTCarrier?
        if #available(iOS 12.1, *) {
            if let newCarrier = networkInfo.serviceSubscriberCellularProviders {
                // pick up the first carrier in the list
                carrier = newCarrier.first?.value
            }
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }
        carrierInfo = [
            TealiumDataKey.carrierMNC: carrier?.mobileNetworkCode ?? "",
            TealiumDataKey.carrierMCC: carrier?.mobileCountryCode ?? "",
            TealiumDataKey.carrierISO: carrier?.isoCountryCode ?? "",
            TealiumDataKey.carrier: carrier?.carrierName ?? ""
        ]
        #endif
        #endif
        return carrierInfo
    }
}
