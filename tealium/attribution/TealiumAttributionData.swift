//
//  TealiumAttribution.swift
//  tealium-swift
//
//  Created by Craig Rouse on 14/03/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if attribution
import TealiumCore
#endif

// Apple Documentation: https://searchads.apple.com/v/advanced/help/c/docs/pdf/attribution-api.pdf

public class TealiumAttributionData: TealiumAttributionDataProtocol {
    var identifierManager: TealiumASIdentifierManagerProtocol
    var adClient: TealiumAdClientProtocol
    let diskStorage: TealiumDiskStorageProtocol
    var persistentAttributionData: PersistentAttributionData?
    public var appleAttributionDetails: PersistentAttributionData?

    /// Init with optional injectable dependencies (for unit testing)￼.
    ///
    /// - Parameters:
    ///     - diskStorage: Class conforming to `TealiumDiskStorageProtocol` to manage persistence. Should be provided by the module￼
    ///     - isSearchAdsEnabled: `Bool` to determine if Apple Search Ads API should be invoked to retrieve attribution data from Apple￼
    ///     - identifierManager: `TealiumASIdentifierManagerProtocol`, a test-friendly implementation of Apple's ASIdentifierManager￼
    ///     - adClient: `TealiumAdClientProtocol`, a test-friendly implementation of Apple's AdClient
    public init(diskStorage: TealiumDiskStorageProtocol,
                isSearchAdsEnabled: Bool,
                identifierManager: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManager.shared,
                adClient: TealiumAdClientProtocol = TealiumAdClient.shared) {
        self.identifierManager = identifierManager
        self.adClient = adClient
        self.diskStorage = diskStorage
        if isSearchAdsEnabled {
            setPersistentAttributionData()
        }
    }

    /// Loads persistent attribution data into memory, or fetches new data if not found.
    func setPersistentAttributionData() {
        if let data = TealiumLegacyMigrator.getLegacyData(forModule: TealiumAttributionKey.moduleName),
            let persistentData = PersistentAttributionData(withDictionary: data) {
            persistentAttributionData = persistentData
            diskStorage.save(self.persistentAttributionData, completion: nil)
        } else {
            diskStorage.retrieve(as: PersistentAttributionData.self) {_, data, _ in

                guard let data = data else {
                    self.appleSearchAdsData { data in
                        self.persistentAttributionData = data
                        self.diskStorage.save(self.persistentAttributionData, completion: nil)
                    }
                    return
                }
                self.persistentAttributionData = data
            }
        }
    }

    /// - Returns: `String` representation of IDFA
    public lazy var idfa: String = {
        return identifierManager.advertisingIdentifier
    }()

    /// - Returns: `String` representation of IDFV
    public lazy var idfv: String = {
        return identifierManager.identifierForVendor
    }()

    /// - Returns: `String` representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    public lazy var isAdvertisingTrackingEnabled: String = {
        return self.identifierManager.isAdvertisingTrackingEnabled
    }()

    /// - Returns: `[String: Any]` of all volatile data (collected at init time): IDFV, IDFA, isTrackingAllowed
    public lazy var volatileData: [String: Any] = {
        return [
            TealiumAttributionKey.idfa: idfa,
            TealiumAttributionKey.idfv: idfv,
            TealiumAttributionKey.isTrackingAllowed: isAdvertisingTrackingEnabled,
        ]
    }()

    /// - Returns:`[String: Any]` containing all attribution data
    public lazy var allAttributionData: [String: Any] = {
        var allData = [String: Any]()
        if let persistentAttributionData = persistentAttributionData {
            allData += persistentAttributionData.toDictionary()
        }
        allData += volatileData
        return allData
    }()

    /// Requests Apple Search Ads data from AdClient API￼.
    /// 
    /// - Parameter completion: Completion block to be executed asynchronously when Search Ads data is returned
    // swiftlint:disable cyclomatic_complexity
    public func appleSearchAdsData(_ completion: @escaping (PersistentAttributionData) -> Void) {
        var appleAttributionDetails = PersistentAttributionData()
        let completionHander = { (details: [String: NSObject]?, error: Error?) in
            // closure callback
            if let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] {
                if let clickedWithin30D = detailsDict[AppleInternalKeys.attribution] as? String {
                    appleAttributionDetails.clickedWithin30D = clickedWithin30D
                }
                if let clickedDate = detailsDict[AppleInternalKeys.clickDate] as? String {
                    appleAttributionDetails.clickedDate = clickedDate
                }
                if let conversionDate = detailsDict[AppleInternalKeys.conversionDate] as? String {
                    appleAttributionDetails.conversionDate = conversionDate
                }
                if let conversionType = detailsDict[AppleInternalKeys.conversionType] as? String {
                    appleAttributionDetails.conversionType = conversionType
                }
                if let purchaseDate = detailsDict[AppleInternalKeys.purchaseDate] as? String {
                    appleAttributionDetails.purchaseDate = purchaseDate
                }
                if let orgName = detailsDict[AppleInternalKeys.orgName] as? String {
                    appleAttributionDetails.orgName = orgName
                }
                if let orgId = detailsDict[AppleInternalKeys.orgId] as? String {
                    appleAttributionDetails.orgId = orgId
                }
                if let campaignId = detailsDict[AppleInternalKeys.campaignId] as? String {
                    appleAttributionDetails.campaignId = campaignId
                }
                if let campaignName = detailsDict[AppleInternalKeys.campaignName] as? String {
                    appleAttributionDetails.campaignName = campaignName
                }
                if let adGroupId = detailsDict[AppleInternalKeys.adGroupId] as? String {
                   appleAttributionDetails.adGroupId = adGroupId
                }
                if let adGroupName = detailsDict[AppleInternalKeys.adGroupName] as? String {
                    appleAttributionDetails.adGroupName = adGroupName
                }
                if let adKeyword = detailsDict[AppleInternalKeys.keyword] as? String {
                    appleAttributionDetails.adKeyword = adKeyword
                }
                if let adKeywordMatchType = detailsDict[AppleInternalKeys.keywordMatchType] as? String {
                    appleAttributionDetails.adKeywordMatchType = adKeywordMatchType
                }
                if let creativeSetName = detailsDict[AppleInternalKeys.creativeSetName] as? String {
                    appleAttributionDetails.creativeSetName = creativeSetName
                }
                if let creativeSetId = detailsDict[AppleInternalKeys.creativeSetId] as? String {
                    appleAttributionDetails.creativeSetId = creativeSetId
                }
                if let region = detailsDict[AppleInternalKeys.region] as? String {
                    appleAttributionDetails.region = region
                }
            }
            self.appleAttributionDetails = appleAttributionDetails
            completion(appleAttributionDetails)
        }
        adClient.requestAttributionDetails(completionHander)
    }
    // swiftlint:enable cyclomatic_complexity
}
