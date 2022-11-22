//
//  TealiumAdClient.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

#if os(iOS)
import AdServices
import Foundation
import iAd

/// Testable replacement for Apple's AdClient.
public protocol TealiumAdClientProtocol {
    func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void)
}

@available(iOS 14.3, *)
public class TealiumHTTPAdClient: TealiumAdClientProtocol {

    public init() {}

    internal func getAttributionData(details: [String: NSObject]?) -> PersistentAttributionData? {
        var appleAttributionDetails = PersistentAttributionData()
        appleAttributionDetails.conversionType = details?[AppleInternalKeys.AAAAttribution.conversionType.rawValue]?.description as? String
        appleAttributionDetails.clickedWithin30D = details?[AppleInternalKeys.AAAAttribution.attribution.rawValue]?.description as? String
        appleAttributionDetails.clickedDate = details?[AppleInternalKeys.AAAAttribution.clickDate.rawValue]?.description as? String
        appleAttributionDetails.adKeyword = details?[AppleInternalKeys.AAAAttribution.keywordId.rawValue]?.description as? String
        appleAttributionDetails.orgId = details?[AppleInternalKeys.AAAAttribution.orgId.rawValue]?.description as? String
        appleAttributionDetails.region = details?[AppleInternalKeys.AAAAttribution.countryOrRegion.rawValue]?.description as? String
        appleAttributionDetails.adGroupId = details?[AppleInternalKeys.AAAAttribution.adGroupId.rawValue]?.description as? String
        appleAttributionDetails.campaignId = details?[AppleInternalKeys.AAAAttribution.campaignId.rawValue]?.description as? String
        appleAttributionDetails.adId = details?[AppleInternalKeys.AAAAttribution.adId.rawValue]?.description as? String
        return appleAttributionDetails
    }

    public func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void) {
        if let adAttributionToken = try? AAAttribution.attributionToken() {
            guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
                completionHandler(nil, AdServiceErrors.invalidUrl)
                return
            }
            let request = NSMutableURLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
            request.httpBody = adAttributionToken.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { [weak self] data, _, error in
                if let error = error {
                    completionHandler(nil, error)
                    return
                }
                do {
                    guard let data = data else {
                        completionHandler(nil, AdServiceErrors.nilData)
                        return
                    }
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: NSObject] {
                        completionHandler(self?.getAttributionData(details: jsonResponse), nil)
                        return
                    } else {
                        completionHandler(nil, AdServiceErrors.invalidJson)
                        return
                    }
                } catch {
                    completionHandler(nil, error)
                }
            })
            task.resume()
        } else {
            completionHandler(nil, AdServiceErrors.invalidToken)
        }
    }
}

/// Implements Apple's AdClient to retrieve Apple Search Ads data.
public class TealiumAdClient: TealiumAdClientProtocol {
    let adClient = ADClient.shared()

    public init() {}

    internal func getAttributionData(details: [String: NSObject]?) -> PersistentAttributionData? {
        var appleAttributionDetails = PersistentAttributionData()
        guard let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] else {
            return nil
        }
        appleAttributionDetails.clickedWithin30D = detailsDict[AppleInternalKeys.attribution] as? String
        appleAttributionDetails.clickedDate = detailsDict[AppleInternalKeys.clickDate] as? String
        appleAttributionDetails.conversionDate = detailsDict[AppleInternalKeys.conversionDate] as? String
        appleAttributionDetails.conversionType = detailsDict[AppleInternalKeys.conversionType] as? String
        appleAttributionDetails.purchaseDate = detailsDict[AppleInternalKeys.purchaseDate] as? String
        appleAttributionDetails.orgName = detailsDict[AppleInternalKeys.orgName] as? String
        appleAttributionDetails.orgId = detailsDict[AppleInternalKeys.orgId] as? String
        appleAttributionDetails.campaignId = detailsDict[AppleInternalKeys.campaignId] as? String
        appleAttributionDetails.campaignName = detailsDict[AppleInternalKeys.campaignName] as? String
        appleAttributionDetails.adGroupId = detailsDict[AppleInternalKeys.adGroupId] as? String
        appleAttributionDetails.adGroupName = detailsDict[AppleInternalKeys.adGroupName] as? String
        appleAttributionDetails.adKeyword = detailsDict[AppleInternalKeys.keyword] as? String
        appleAttributionDetails.adKeywordMatchType = detailsDict[AppleInternalKeys.keywordMatchType] as? String
        appleAttributionDetails.creativeSetName = detailsDict[AppleInternalKeys.creativeSetName] as? String
        appleAttributionDetails.creativeSetId = detailsDict[AppleInternalKeys.creativeSetId] as? String
        appleAttributionDetails.region = detailsDict[AppleInternalKeys.region] as? String
        appleAttributionDetails.adId = detailsDict[AppleInternalKeys.adId] as? String
        return appleAttributionDetails
    }

    public func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void) {
        adClient.requestAttributionDetails { [weak self] details, error in
            completionHandler(self?.getAttributionData(details: details), error)
        }
    }
}

@available(iOS 14.3, *)
public extension TealiumHTTPAdClient {
    enum AdServiceErrors: Error {
        case invalidUrl
        case invalidJson
        case nilData
        case invalidToken
    }
}
#endif
