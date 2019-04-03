//
//  FirebaseCommands.swift
//  FirebaseTest
//
//  Created by Craig Rouse on 18/12/2017.
//  Copyright © 2017 Tealium. All rights reserved.
//

import Foundation
import FirebaseAnalytics
import Firebase
import TealiumSwift

class FirebaseCommands: TealiumRemoteCommand {

    enum keyNames {
        static let sessionTimeout = "firebase_session_timeout_seconds"
        static let minSeconds = "firebase_session_minimum_seconds"
        static let analyticsEnabled = "firebase_analytics_enabled"
        static let logLevel = "firebase_log_level"
        static let eventName = "firebase_event_name"
        static let eventParams = "firebase_event_params"
        static let screenName = "firebase_screen_name"
        static let screenClass = "firebase_screen_class"
        static let userPropertyName = "firebase_property_name"
        static let userPropertyValue = "firebase_property_value"
        static let userId = "firebase_user_id"
        static let commandName = "command_name"
    }

    class func firebaseCommand() -> TealiumRemoteCommand {
        return TealiumRemoteCommand(commandId: "firebaseAnalytics",
                                    description: "Firebase Analytics Remote Command") {
            (response) in
            let commandPayload = response.payload()
            guard let command = commandPayload["command_name"] as? String else {
                return
            }
            // allow multiple commands
            let commandSplit = command.split(separator: ",")
            for singleCommandName in commandSplit {
                let trimmedCommandName = singleCommandName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                switch trimmedCommandName {
                case "config":
                    var firebaseSessionTimeout: TimeInterval?
                    var firebaseSessionMinimumSeconds: TimeInterval?
                    var firebaseAnalyticsEnabled: Bool?
                    if let sessionTimeout = commandPayload[keyNames.sessionTimeout] as? String {
                        firebaseSessionTimeout = TimeInterval(sessionTimeout)
                    }
                    if let sessionMinimumSeconds = commandPayload[keyNames.minSeconds] as? String {
                        firebaseSessionMinimumSeconds = TimeInterval(sessionMinimumSeconds)
                    }
                    if let analyticsEnabled = commandPayload[keyNames.analyticsEnabled] as? String {
                        firebaseAnalyticsEnabled = Bool(analyticsEnabled)
                    }
                    let logLevel = commandPayload[keyNames.logLevel] as? String
                    FirebaseCommands.createAnalyticsConfig(firebaseSessionTimeout, firebaseSessionMinimumSeconds, firebaseAnalyticsEnabled, logLevel)
                case "logEvent":
                    guard let name = commandPayload[keyNames.eventName] as? String else {
                        return
                    }
                    let eventName = FirebaseCommands.mapEventNames(name)
                    guard let params = commandPayload[keyNames.eventParams] as? Dictionary<String, Any> else {
                        return
                    }
                    var normalizedParams = [String: Any]()
                    for param in params {
                        let newKeyName = FirebaseCommands.paramsMap(param.key)
                        normalizedParams[newKeyName] = param.value
                    }
                    FirebaseCommands.logEvent(eventName, normalizedParams)
                case "setScreenName":
                    guard let screenName = commandPayload[keyNames.screenName] as? String else {
                        return
                    }
                    let screenClass = commandPayload[keyNames.screenClass] as? String
                    FirebaseCommands.setScreenName(screenName, screenClass)
                case "setUserProperty":
                    guard let propertyName = commandPayload[keyNames.userPropertyName] as? String else {
                        return
                    }
                    guard let propertyValue = commandPayload[keyNames.userPropertyValue] as? String else {
                        return
                    }
                    FirebaseCommands.setUserProperty(propertyName, value: propertyValue)
                case "setUserId":
                    guard let userId = commandPayload[keyNames.userId] as? String else {
                        return
                    }
                    FirebaseCommands.setUserId(userId)
                default:
                    return
                }
            }
        }
    }

    static let firebaseConfiguration = FirebaseConfiguration.shared

    class func createAnalyticsConfig(_ sessionTimeoutSeconds: TimeInterval?, _ minimumSessionSeconds: TimeInterval?, _ analyticsEnabled: Bool?, _ logLevel: String?) {
        if let sessionTimeoutSeconds = sessionTimeoutSeconds {
            Analytics.setSessionTimeoutInterval(sessionTimeoutSeconds)
        }
        if let analyticsEnabled = analyticsEnabled {
            Analytics.setAnalyticsCollectionEnabled(analyticsEnabled)
        }
        if let logLevel = logLevel {
            firebaseConfiguration.setLoggerLevel(FirebaseCommands.parseLogLevel(logLevel))
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    class func logEvent(_ name: String, _ params: Dictionary<String, Any>) {
        Analytics.logEvent(name, parameters: params)
    }

    class func setUserProperty(_ property: String, value: String) {
        if value == "" {
            Analytics.setUserProperty(nil, forName: property)
        } else {
            Analytics.setUserProperty(value, forName: property)
        }
    }

    class func setUserId(_ id: String) {
        Analytics.setUserID(id)
    }

    class func setScreenName(_ screenName: String, _ screenClass: String?) {
        Analytics.setScreenName(screenName, screenClass: screenClass)
    }

    class func parseLogLevel(_ logLevel: String) -> FirebaseLoggerLevel {
        switch logLevel {
        case "min":
            return FirebaseLoggerLevel.min
        case "max":
            return FirebaseLoggerLevel.max
        case "error":
            return FirebaseLoggerLevel.error
        case "debug":
            return FirebaseLoggerLevel.debug
        case "notice":
            return FirebaseLoggerLevel.notice
        case "warning":
            return FirebaseLoggerLevel.warning
        case "info":
            return FirebaseLoggerLevel.info
        default:
            return FirebaseLoggerLevel.min
        }
    }

    class func mapEventNames(_ eventName: String) -> String {
        let eventsMap = [
            "add_payment_info": AnalyticsEventAddPaymentInfo,
            "add_to_cart": AnalyticsEventAddToCart,
            "add_to_wishlist": AnalyticsEventAddToWishlist,
            "app_open": AnalyticsEventAppOpen,
            "event_begin_checkout": AnalyticsEventBeginCheckout,
            "event_campaign_details": AnalyticsEventCampaignDetails,
            "event_checkout_progress": AnalyticsEventCheckoutProgress,
            "event_earn_virtual_currency": AnalyticsEventEarnVirtualCurrency,
            "event_ecommerce_purchase": AnalyticsEventEcommercePurchase,
            "event_generate_lead": AnalyticsEventGenerateLead,
            "event_join_group": AnalyticsEventJoinGroup,
            "event_level_up": AnalyticsEventLevelUp,
            "event_login": AnalyticsEventLogin,
            "event_post_score": AnalyticsEventPostScore,
            "event_present_offer": AnalyticsEventPresentOffer,
            "event_purchase_refund": AnalyticsEventPurchaseRefund,
            "event_remove_cart": AnalyticsEventRemoveFromCart,
            "event_search": AnalyticsEventSearch,
            "event_select_content": AnalyticsEventSelectContent,
            "event_set_checkout_option": AnalyticsEventSetCheckoutOption,
            "event_share": AnalyticsEventShare,
            "event_signup": AnalyticsEventSignUp,
            "event_spend_virtual_currency": AnalyticsEventSpendVirtualCurrency,
            "event_tutorial_begin": AnalyticsEventTutorialBegin,
            "event_tutorial_complete": AnalyticsEventTutorialComplete,
            "event_unlock_achievement": AnalyticsEventUnlockAchievement,
            "event_view_item": AnalyticsEventViewItem,
            "event_view_item_list": AnalyticsEventViewItemList,
            "event_view_search_results": AnalyticsEventViewSearchResults
        ]
        return eventsMap[eventName] ?? eventName
    }

    class func paramsMap(_ paramName: String) -> String {
        let paramsMap = [
            "param_achievement_id": AnalyticsParameterAchievementID,
            "param_ad_network_click_id": AnalyticsParameterAdNetworkClickID,
            "param_affiliation": AnalyticsParameterAffiliation,
            "param_cp1": AnalyticsParameterCP1,
            "param_campaign": AnalyticsParameterCampaign,
            "param_character": AnalyticsParameterCharacter,
            "param_checkout_option": AnalyticsParameterCheckoutOption,
            "param_checkout_step": AnalyticsParameterCheckoutStep,
            "param_content": AnalyticsParameterContent,
            "param_content_type": AnalyticsParameterContentType,
            "param_coupon": AnalyticsParameterCoupon,
            "param_creative_name": AnalyticsParameterCreativeName,
            "param_creative_slot": AnalyticsParameterCreativeSlot,
            "param_currency": AnalyticsParameterCurrency,
            "param_destination": AnalyticsParameterDestination,
            "param_end_date": AnalyticsParameterEndDate,
            "param_flight_number": AnalyticsParameterFlightNumber,
            "param_group_id": AnalyticsParameterGroupID,
            "param_index": AnalyticsParameterIndex,
            "param_item_brand": AnalyticsParameterItemBrand,
            "param_item_category": AnalyticsParameterItemCategory,
            "param_item_id": AnalyticsParameterItemID,
            "param_item_list": AnalyticsParameterItemList,
            "param_item_location_id": AnalyticsParameterItemLocationID,
            "param_item_name": AnalyticsParameterItemName,
            "param_item_variant": AnalyticsParameterItemVariant,
            "param_level": AnalyticsParameterLevel,
            "param_location": AnalyticsParameterLocation,
            "param_medium": AnalyticsParameterMedium,
            "param_number_nights": AnalyticsParameterNumberOfNights,
            "param_number_pax": AnalyticsParameterNumberOfPassengers,
            "param_number_rooms": AnalyticsParameterNumberOfRooms,
            "param_origin": AnalyticsParameterOrigin,
            "param_price": AnalyticsParameterPrice,
            "param_quantity": AnalyticsParameterQuantity,
            "param_score": AnalyticsParameterScore,
            "param_search_term": AnalyticsParameterSearchTerm,
            "param_shipping": AnalyticsParameterShipping,
            "param_signup_method": AnalyticsParameterSignUpMethod,
            "param_source": AnalyticsParameterSource,
            "param_start_date": AnalyticsParameterStartDate,
            "param_tax": AnalyticsParameterTax,
            "param_term": AnalyticsParameterTerm,
            "param_transaction_id": AnalyticsParameterTransactionID,
            "param_travel_class": AnalyticsParameterTravelClass,
            "param_value": AnalyticsParameterValue,
            "param_virtual_currency_name": AnalyticsParameterVirtualCurrencyName,
            "param_user_signup_method": AnalyticsUserPropertySignUpMethod
        ]
        return paramsMap[paramName] ?? paramName
    }

}
