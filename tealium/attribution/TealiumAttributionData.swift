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

public class TealiumAttributionData: TealiumAttributionDataProtocol {
    var identifierManager: TealiumASIdentifierManagerProtocol
    var adClient: TealiumAdClientProtocol

    /// - Returns: [String: Any]? of all Apple Search Ads info, if available
    public var appleAttributionDetails: [String: Any]?

    /// Init with optional injectable dependencies (for unit testing)
    /// - Parameters:
    /// - identifierManager: TealiumASIdentifierManagerProtocol, a test-friendly implementation of Apple's ASIdentifierManager
    /// - adClient: TealiumAdClientProtocol, a test-friendly implementation of Apple's AdClient
    public init(identifierManager: TealiumASIdentifierManagerProtocol = TealiumASIdentifierManager.shared,
                adClient: TealiumAdClientProtocol = TealiumAdClient.shared) {
        self.identifierManager = identifierManager
        self.adClient = adClient
    }

    /// - Returns: String representation of IDFA
    public lazy var idfa: String = {
        return identifierManager.advertisingIdentifier
    }()

    /// - Returns: String representation of IDFV
    public lazy var idfv: String = {
        return identifierManager.identifierForVendor
    }()

    /// - Returns: String representation of Limit Ad Tracking setting (true if tracking allowed, false if disabled)
    public lazy var isAdvertisingTrackingEnabled: String = {
        return self.identifierManager.isAdvertisingTrackingEnabled
    }()

    /// - Returns: All volatile data (collected at init time): IDFV, IDFA, isTrackingAllowed
    public lazy var volatileData: [String: Any] = {
        return [
            TealiumAttributionKey.idfa: idfa,
            TealiumAttributionKey.idfv: idfv,
            TealiumAttributionKey.isTrackingAllowed: isAdvertisingTrackingEnabled,
        ]
    }()

    /// - Returns: [String: Any] containing all attribution data
    public lazy var allAttributionData: [String: Any] = {
        var allData = [String: Any]()
        if let appleAttributionDetails = appleAttributionDetails {
            allData += appleAttributionDetails
        }
        allData += volatileData
        return allData
    }()

    /// Requests Apple Search Ads data from AdClient API
    /// - Parameter completion: Completion block to be executed asynchronously when Search Ads data is returned
    public func appleSearchAdsData(_ completion: @escaping ([String: Any]) -> Void) {
        var appleAttributionDetails = [String: Any]()
        let completionHander = { (details: [String: NSObject]?, error: Error?) in
            // closure callback
            if let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] {
                if let att = detailsDict[AppleInternalKeys.attribution] as? String {
                    appleAttributionDetails[TealiumAttributionKey.clickedWithin30D] = att
                }
                if let dat = detailsDict[AppleInternalKeys.clickDate] as? String {
                    appleAttributionDetails[TealiumAttributionKey.clickedDate] = dat
                }
                if let convDt = detailsDict[AppleInternalKeys.conversionDate] as? String {
                    appleAttributionDetails[TealiumAttributionKey.conversionDate] = convDt
                }
                if let orgName = detailsDict[AppleInternalKeys.orgName] as? String {
                    appleAttributionDetails[TealiumAttributionKey.orgName] = orgName
                }
                if let cmpId = detailsDict[AppleInternalKeys.campaignId] as? String {
                    appleAttributionDetails[TealiumAttributionKey.campaignId] = cmpId
                }
                if let cmpName = detailsDict[AppleInternalKeys.campaignName] as? String {
                    appleAttributionDetails[TealiumAttributionKey.campaignName] = cmpName
                }
                if let adGrpId = detailsDict[AppleInternalKeys.adGroupId] as? String {
                   appleAttributionDetails[TealiumAttributionKey.adGroupId] = adGrpId
                }
                if let adGrpName = detailsDict[AppleInternalKeys.adGroupName] as? String {
                    appleAttributionDetails[TealiumAttributionKey.adGroupName] = adGrpName
                }
                if let keyword = detailsDict[AppleInternalKeys.keyword] as? String {
                    appleAttributionDetails[TealiumAttributionKey.adKeyword] = keyword
                }
                self.appleAttributionDetails = appleAttributionDetails
            }
            completion(appleAttributionDetails)
        }
        adClient.requestAttributionDetails(completionHander)
    }
}
