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
    static var shared: TealiumAdClientProtocol { get }
    func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void)
}

/// Implements Apple's AdClient to retrieve Apple Search Ads data.
public class TealiumAdClient: TealiumAdClientProtocol {
    let adClient = ADClient.shared()
    public static var shared: TealiumAdClientProtocol = TealiumAdClient()

    private init() {

    }

    func getAAAttributionData(details: [String: NSObject]?) -> PersistentAttributionData {
        var appleAttributionDetails = PersistentAttributionData()
        if let conversionType = details?[AppleInternalKeys.AAAAttribution.conversionType.rawValue] as? String {
            appleAttributionDetails.conversionType = conversionType
        }
        if let clickedWithin30D = details?[AppleInternalKeys.attribution] as? String {
            appleAttributionDetails.clickedWithin30D = clickedWithin30D
        }
        if let clickedDate = details?[AppleInternalKeys.AAAAttribution.clickDate.rawValue] as? String {
            appleAttributionDetails.clickedDate = clickedDate
        }
        if let keywordId = details?[AppleInternalKeys.AAAAttribution.keywordId.rawValue] as? String {
            appleAttributionDetails.adKeyword = keywordId
        }
        if let orgId = details?[AppleInternalKeys.AAAAttribution.orgId.rawValue] as? String {
            appleAttributionDetails.orgId = orgId
        }
        if let countryOrRegion = details?[AppleInternalKeys.AAAAttribution.countryOrRegion.rawValue] as? String {
            appleAttributionDetails.region = countryOrRegion
        }
        if let adGroupId = details?[AppleInternalKeys.AAAAttribution.adGroupId.rawValue] as? String {
            appleAttributionDetails.adGroupId = adGroupId
        }
        if let campaignId = details?[AppleInternalKeys.AAAAttribution.campaignId.rawValue] as? String {
            appleAttributionDetails.campaignId = campaignId
        }
        if let adId = details?[AppleInternalKeys.AAAAttribution.adId.rawValue] as? String {
            appleAttributionDetails.adId = adId
        }
        return appleAttributionDetails
    }

    // swiftlint:disable cyclomatic_complexity
    func getAttributionData(details: [String: NSObject]?) -> PersistentAttributionData? {
        var appleAttributionDetails = PersistentAttributionData()
        guard let detailsDict = details?[AppleInternalKeys.objectVersion] as? [String: Any] else {
            return nil
        }
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
        return appleAttributionDetails
    }

    public func requestAttributionDetails(_ completionHandler: @escaping (PersistentAttributionData?, Error?) -> Void) {
        if #available(iOS 14.3, *) {
            if let adAttributionToken = try? AAAttribution.attributionToken() {
                guard let url = URL(string: "https://api-adservices.apple.com/api/v1/") else {
                    completionHandler(nil, AdServiceErrors.invalidUrl)
                    return
                }
                let request = NSMutableURLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
                request.httpBody = adAttributionToken.data(using: .utf8)
                let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {[weak self] data, _, error in
                    if let error = error {
                        completionHandler(nil, error)
                        return
                    }
                    do {
                        guard let data = data else {
                            completionHandler(nil, AdServiceErrors.nilData)
                            return
                        }
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: NSObject] {
                            completionHandler(self?.getAAAttributionData(details: jsonResponse), nil)
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
        } else {
            adClient.requestAttributionDetails { [weak self] details, error in
                completionHandler(self?.getAttributionData(details: details), error)
            }
        }
    }
}

public extension TealiumAdClient {
    enum AdServiceErrors: Error {
        case invalidUrl
        case invalidJson
        case nilData
        case invalidToken
    }
}
#endif
