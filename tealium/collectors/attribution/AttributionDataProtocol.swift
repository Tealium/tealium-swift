//
//  AttributionDataProtocol.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if attribution
import TealiumCore
#endif

public protocol AttributionDataProtocol {

    /// - Returns: `[String: Any]` containing all attribution data
    var allAttributionData: [String: Any] { get }

    /// - Returns: `PersistentAttributionData` containing all Apple Search Ads info, if available
    var appleAttributionDetails: `PersistentAttributionData`? { get set }

    /// - Returns: `String` representation of IDFA
    var idfa: String { get }

    /// - Returns: `String` representation of IDFV
    var idfv: String { get }

    /// - Returns: `[String: Any]` of all volatile data (collected at init time): IDFV, IDFA, isTrackingAllowed
    var volatileData: [String: Any] { get }

    /// - Returns: `String` representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    var isAdvertisingTrackingEnabled: String { get }

    /// Requests Apple Search Ads data from AdClient API￼.
    ///
    /// - Parameter completion: Completion block to be executed asynchronously when Search Ads data is returned
    func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData) -> Void)

    /// Calls the `SKAdNetwork.updateConversionValue()` method
    /// - Parameter dispatch: `TealiumRequest`
    func updateConversionValue(from dispatch: TealiumRequest)
}
#endif
