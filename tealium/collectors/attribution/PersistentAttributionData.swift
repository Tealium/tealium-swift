//
//  PersistentAttributionData.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation
#if attribution
import TealiumCore
#endif

public struct PersistentAttributionData: Codable {

    // Some of these keys are left here for backwards compatibility.
    // Old iAd framework keys might be stored on device and can still be read.
    var clickedWithin30D: String?,
        clickedDate: String?,
        conversionDate: String?,
        conversionType: String?,
        purchaseDate: String?,
        orgName: String?,
        orgId: String?,
        campaignId: String?,
        campaignName: String?,
        adGroupId: String?,
        adGroupName: String?,
        adKeyword: String?,
        adKeywordMatchType: String?,
        creativeSetName: String?,
        creativeSetId: String?,
        region: String?,
        adId: String?

    public subscript(_ key: String) -> String? {
        return self.dictionary[key]
    }

    public enum CodingKeys: String, CodingKey {
        case clickedWithin30D = "ad_user_clicked_last_30_days"
        case clickedDate = "ad_user_date_clicked"
        case conversionDate = "ad_user_date_converted"
        case conversionType = "ad_user_conversion_type"
        case purchaseDate = "ad_purchase_date"
        case orgName = "ad_org_name"
        case orgId = "ad_org_id"
        case campaignId = "ad_campaign_id"
        case campaignName = "ad_campaign_name"
        case adId = "ad_id"
        case adGroupId = "ad_group_id"
        case adGroupName = "ad_group_name"
        case adKeyword = "ad_keyword"
        case adKeywordMatchType = "ad_keyword_matchtype"
        case creativeSetName = "ad_creativeset_name"
        case creativeSetId = "ad_creativeset_id"
        case region = "ad_region"
    }

    public var count: Int {
        return Mirror(reflecting: self).children.count
    }

    init() {
    }

    public init?(withDictionary dictionary: [String: Any]) {
        if let json = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
            if let data = try? Tealium.jsonDecoder.decode(PersistentAttributionData.self, from: json) {
                self = data
            }
        }
    }

    /// - Returns: `[String: String]`
    public var dictionary: [String: String] {
        // note: compiler cannot type-check in reasonable time, so assignment and return split up into separate statements
        let attributionData: [String: String] = [TealiumDataKey.adClickedWithin30D: clickedWithin30D ?? "",
                                                 TealiumDataKey.adClickedDate: clickedDate ?? "",
                                                 TealiumDataKey.adConversionDate: conversionDate ?? "",
                                                 TealiumDataKey.adConversionType: conversionType ?? "",
                                                 TealiumDataKey.adPurchaseDate: purchaseDate ?? "",
                                                 TealiumDataKey.adOrgName: orgName ?? "",
                                                 TealiumDataKey.adOrgId: orgId ?? "",
                                                 TealiumDataKey.adCampaignId: campaignId ?? "",
                                                 TealiumDataKey.adCampaignName: campaignName ?? "",
                                                 TealiumDataKey.adId: adId ?? "",
                                                 TealiumDataKey.adGroupId: adGroupId ?? "",
                                                 TealiumDataKey.adGroupName: adGroupName ?? "",
                                                 TealiumDataKey.adKeyword: adKeyword ?? "",
                                                 TealiumDataKey.adKeywordMatchType: adKeywordMatchType ?? "",
                                                 TealiumDataKey.adCreativeSetName: creativeSetName ?? "",
                                                 TealiumDataKey.adCreativeSetId: creativeSetId ?? "",
                                                 TealiumDataKey.adRegion: region ?? "",
        ]

        return attributionData.filter {
            $0.value != ""
        }
    }

    func isEmpty() -> Bool {
        return dictionary.isEmpty
    }

}
#endif
