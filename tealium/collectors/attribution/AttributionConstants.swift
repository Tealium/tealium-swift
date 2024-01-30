//
//  AttributionConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

#if attribution
import TealiumCore
#endif

extension TealiumDataKey {
    // Advertising IDs
    static let idfa = "device_advertising_id"
    static let idfv = "device_advertising_vendor_id"
    static let isTrackingAllowed = "device_advertising_enabled"
    // ATTrackingManager
    static let trackingAuthorization = "device_tracking_authorization"
    // iAd Attribution keys
    static let adClickedWithin30D = "ad_user_clicked_last_30_days"
    static let adClickedDate = "ad_user_date_clicked"
    static let adConversionDate = "ad_user_date_converted"
    static let adConversionType = "ad_user_conversion_type"
    static let adOrgName = "ad_org_name"
    static let adOrgId = "ad_org_id"
    static let adPurchaseDate = "ad_purchase_date"
    static let adCampaignId = "ad_campaign_id"
    static let adCampaignName = "ad_campaign_name"
    static let adId = "ad_id"
    static let adGroupId = "ad_group_id"
    static let adGroupName = "ad_group_name"
    static let adKeyword = "ad_keyword"
    static let adKeywordMatchType = "ad_keyword_matchtype"
    static let adCreativeSetId = "ad_creativeset_id"
    static let adCreativeSetName = "ad_creativeset_name"
    static let adRegion = "ad_region"
}

public struct AttributionKey {
    public static let allCases = [
        TealiumDataKey.idfa,
        TealiumDataKey.idfv,
        TealiumDataKey.isTrackingAllowed,
        TealiumDataKey.trackingAuthorization,
        TealiumDataKey.adClickedWithin30D,
        TealiumDataKey.adClickedDate,
        TealiumDataKey.adConversionDate,
        TealiumDataKey.adConversionType,
        TealiumDataKey.adOrgName,
        TealiumDataKey.adOrgId,
        TealiumDataKey.adPurchaseDate,
        TealiumDataKey.adCampaignId,
        TealiumDataKey.adCampaignName,
        TealiumDataKey.adId,
        TealiumDataKey.adGroupId,
        TealiumDataKey.adGroupName,
        TealiumDataKey.adKeyword,
        TealiumDataKey.adKeywordMatchType,
        TealiumDataKey.adCreativeSetId,
        TealiumDataKey.adCreativeSetName,
        TealiumDataKey.adRegion
    ]

    // Internal module keys
    static let moduleName = "attribution"
}

public struct AppleInternalKeys {
    enum AAAAttribution: String, CaseIterable {
        case conversionType
        case attribution
        case keywordId
        case orgId
        case countryOrRegion
        case adGroupId
        case campaignId
        case adId
        case clickDate
    }
}

public enum TrackingAuthorizationDescription {
    static let authorized = "authorized"
    static let denied = "denied"
    static let restricted = "restricted"
    static let notDetermined = "notDetermined"
}
#endif
