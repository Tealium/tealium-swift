//
//  AttributionData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS) && !targetEnvironment(macCatalyst)
import Foundation
#if attribution
import TealiumCore
#endif

// Apple Documentation: https://searchads.apple.com/v/advanced/help/c/docs/pdf/attribution-api.pdf

public class AttributionData: AttributionDataProtocol {
    var identifierManager: TealiumASIdentifierManagerProtocol
    var adClient: TealiumAdClientProtocol
    var config: TealiumConfig
    let diskStorage: TealiumDiskStorageProtocol
    var persistentAttributionData: PersistentAttributionData?
    public var adAttribution: TealiumSKAdAttributionProtocol?

    /// Init with optional injectable dependencies (for unit testing)￼.
    ///
    /// - Parameters:
    ///     - diskStorage: Class conforming to `TealiumDiskStorageProtocol` to manage persistence. Should be provided by the module￼
    ///     - isSearchAdsEnabled: `Bool` to determine if Apple Search Ads API should be invoked to retrieve attribution data from Apple￼
    ///     - identifierManager: `TealiumASIdentifierManagerProtocol`, a test-friendly implementation of Apple's ASIdentifierManager￼
    ///     - adClient: `TealiumAdClientProtocol`, a test-friendly implementation of Apple's AdClient
    public init(config: TealiumConfig,
                diskStorage: TealiumDiskStorageProtocol,
                identifierManager: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManager.shared,
                adClient: TealiumAdClientProtocol? = nil,
                adAttribution: TealiumSKAdAttributionProtocol? = nil) {
        self.config = config
        self.identifierManager = identifierManager
        if let adClient = adClient {
            self.adClient = adClient
        } else if #available(iOS 14.3, *) {
            self.adClient = TealiumHTTPAdClient()
        } else {
            self.adClient = TealiumAdClient()
        }
        self.diskStorage = diskStorage
        if self.config.skAdAttributionEnabled {
            self.adAttribution = adAttribution ?? TealiumSKAdAttribution(config: self.config)
            self.adAttribution?.registerAdNetwork()
        }
        if self.config.searchAdsEnabled {
            setPersistentAttributionData()
        }
    }

    /// Loads persistent attribution data into memory, or fetches new data if not found.
    func setPersistentAttributionData() {
        guard let currentData = diskStorage.retrieve(as: PersistentAttributionData.self), !currentData.isEmpty() else {
            self.appleSearchAdsData { data in
                if let data = data {
                    self.persistentAttributionData = data
                    self.diskStorage.save(self.persistentAttributionData, completion: nil)
                }
            }
            return
        }
        self.persistentAttributionData = currentData
    }

    /// - Returns: `String` representation of IDFA
    public var idfa: String {
        return identifierManager.advertisingIdentifier
    }

    /// - Returns: `String` representation of IDFV
    public lazy var idfv: String = {
        return identifierManager.identifierForVendor
    }()

    /// - Returns: `String` representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    public var isAdvertisingTrackingEnabled: String {
        return self.identifierManager.isAdvertisingTrackingEnabled
    }

    /// - Returns: `String` representation of ATTrackingManager.trackingAuthorizationStatus
    public var trackingAuthorizationStatus: String {
        return self.identifierManager.trackingAuthorizationStatus
    }

    /// - Returns: `[String: Any]` of all volatile data (collected at init time): IDFV, IDFA, isTrackingAllowed
    public var volatileData: [String: Any] {
        return [
            TealiumDataKey.idfa: idfa,
            TealiumDataKey.idfv: idfv,
            TealiumDataKey.isTrackingAllowed: isAdvertisingTrackingEnabled,
            TealiumDataKey.trackingAuthorization: trackingAuthorizationStatus
        ]
    }

    /// - Returns:`[String: Any]` containing all attribution data
    public var allAttributionData: [String: Any] {
        var all = [String: Any]()
        if let persistentAttributionData = persistentAttributionData {
            all += persistentAttributionData.dictionary
        }
        all += volatileData
        return all
    }

    /// Requests Apple Search Ads data from AdClient API￼.
    ///
    /// - Parameter completion: Completion block to be executed asynchronously when Search Ads data is returned
    func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData?) -> Void) {
        let completionHandler = { (details: PersistentAttributionData?, _: Error?) in
            completion(details)
        }
        adClient.requestAttributionDetails(completionHandler)
    }

    public func updateConversionValue(from dispatch: TealiumRequest) {
        if let dispatch = dispatch as? TealiumTrackRequest {
            adAttribution?.extractConversionInfo(from: dispatch)
        } else if let dispatch = dispatch as? TealiumBatchTrackRequest {
            dispatch.trackRequests.forEach {
                adAttribution?.extractConversionInfo(from: $0)
            }
        }
    }
}
#endif
