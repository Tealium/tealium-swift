//
//  AttributionConstants.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import Foundation

public struct AttributionKey {
    public static let allCases = [
        AttributionKey.idfa,
        AttributionKey.idfv,
        AttributionKey.isTrackingAllowed,
        AttributionKey.trackingAuthorization,
        AttributionKey.clickedWithin30D,
        AttributionKey.clickedDate,
        AttributionKey.conversionDate,
        AttributionKey.conversionType,
        AttributionKey.orgName,
        AttributionKey.orgId,
        AttributionKey.purchaseDate,
        AttributionKey.campaignId,
        AttributionKey.campaignName,
        AttributionKey.adGroupId,
        AttributionKey.adGroupName,
        AttributionKey.adKeyword,
        AttributionKey.adKeywordMatchType,
        AttributionKey.creativeSetId,
        AttributionKey.creativeSetName,
        AttributionKey.region
    ]

    // Internal module keys
    static let moduleName = "attribution"
    static let isSearchAdsEnabled = "com.tealium.attribution.searchads.enable"
    static let isSKAdAttributionEnabled = "com.tealium.attribution.skadattribution.enable"
    // Advertising IDs
    static let idfa = "device_advertising_id"
    static let idfv = "device_advertising_vendor_id"
    static let isTrackingAllowed = "device_advertising_enabled"
    // ATTrackingManager
    static let trackingAuthorization = "device_tracking_authorization"
    // iAd Attribution keys
    static let clickedWithin30D = "ad_user_clicked_last_30_days"
    static let clickedDate = "ad_user_date_clicked"
    static let conversionDate = "ad_user_date_converted"
    static let conversionType = "ad_user_conversion_type"
    static let orgName = "ad_org_name"
    static let orgId = "ad_org_id"
    static let purchaseDate = "ad_purchase_date"
    static let campaignId = "ad_campaign_id"
    static let campaignName = "ad_campaign_name"
    static let adGroupId = "ad_group_id"
    static let adGroupName = "ad_group_name"
    static let adKeyword = "ad_keyword"
    static let adKeywordMatchType = "ad_keyword_matchtype"
    static let creativeSetId = "ad_creativeset_id"
    static let creativeSetName = "ad_creativeset_name"
    static let region = "ad_region"
}

public struct AppleInternalKeys {
    static let allCases = [
        AppleInternalKeys.attribution,
        AppleInternalKeys.orgName,
        AppleInternalKeys.orgId,
        AppleInternalKeys.campaignId,
        AppleInternalKeys.campaignName,
        AppleInternalKeys.clickDate,
        AppleInternalKeys.purchaseDate,
        AppleInternalKeys.conversionDate,
        AppleInternalKeys.conversionType,
        AppleInternalKeys.adGroupId,
        AppleInternalKeys.adGroupName,
        AppleInternalKeys.keyword,
        AppleInternalKeys.keywordMatchType,
        AppleInternalKeys.creativeSetId,
        AppleInternalKeys.creativeSetName,
        AppleInternalKeys.region
    ]

    static let attribution = "iad-attribution"
    static let orgName = "iad-org-name"
    static let orgId = "iad-org-id" //
    static let campaignId = "iad-campaign-id"
    static let campaignName = "iad-campaign-name"
    static let clickDate = "iad-click-date"
    static let purchaseDate = "iad-purchase-date" //
    static let conversionDate = "iad-conversion-date"
    static let conversionType = "iad-conversion-type" //
    static let adGroupId = "iad-adgroup-id"
    static let adGroupName = "iad-adgroup-name"
    static let keyword = "iad-keyword"
    static let keywordMatchType = "iad-keyword-matchtype" //
    static let creativeSetId = "iad-creativeset-id" //
    static let creativeSetName = "iad-creativeset-name" //
    static let region = "iad-country-or-region" //
    static let objectVersion = "Version3.1" // This is the root key for the returned data
}

public enum TrackingAuthorizationDescription {
    static let authorized = "authorized"
    static let denied = "denied"
    static let restricted = "restricted"
    static let notDetermined = "notDetermined"
}
#endif
