//
//  JSONRemoteCommandPayloadBuilderTests.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Enrico Zannini on 22/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import XCTest
import TealiumCore
@testable import TealiumRemoteCommands

final class JSONRemoteCommandPayloadBuilderTests: XCTestCase {
    typealias Builder = JSONRemoteCommandPayloadBuilder
    
    func testMapPayload() {
        let payload: [String: Any] = ["product_id": ["ABC123"], "product_name": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00"]
        let lookup = ["campaign_keywords": "cp1",
                      "campaign": "campaign",
                      "checkout_option": "checkout_option",
                      "checkout_step": "checkout_step",
                      "content": "content",
                      "content_type": "content_type",
                      "coupon": "coupon",
                      "product_brand": "item_brand",
                      "product_category": "item_category",
                      "product_id": "item_id",
                      "product_list": "item_list",
                      "product_location_id": "item_location_id",
                      "product_name": "item_name",
                      "product_variant": "item_variant",
                      "campaign_medium": "medium",
                      "product_unit_price": "price",
                      "product_quantity": "quantity",
                      "search_keyword": "search_term",
                      "order_shipping_amount": "shipping",
                      "order_tax_amount": "tax",
                      "order_id": "transaction_id",
                      "order_total": "value",
                      "event_title": "event_name",
                      "tealium_event": "command_name",
                      "customer_id": "user_id"]
        let expectedOutput: [String: Any] = ["item_id": ["ABC123"], "item_name": ["milk chocolate"], "item_brand": ["see's"], "price": ["19.99"], "quantity": ["1"], "user_id": "CUST234324", "transaction_id": "ORD239847", "event_name": "ecommerce_purchase", "tax": "1.99", "shipping": "5.00"]
        let actualOutput: [String: Any] = Builder.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }
    
    func testMapPayloadWithMultipleMappings() {
        let payload: [String: Any] = ["product_id": ["ABC123"], "product_name": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00"]
        let lookup = ["campaign_keywords": "cp1",
                      "campaign": "campaign",
                      "checkout_option": "checkout_option",
                      "checkout_step": "checkout_step",
                      "content": "content",
                      "content_type": "content_type",
                      "coupon": "coupon",
                      "product_brand": "item_brand",
                      "product_category": "item_category",
                      "product_id": "item_id,item_sku",
                      "product_list": "item_list",
                      "product_location_id": "item_location_id",
                      "product_name": "item_name",
                      "product_variant": "item_variant",
                      "campaign_medium": "medium",
                      "product_unit_price": "price",
                      "product_quantity": "quantity",
                      "search_keyword": "search_term",
                      "order_shipping_amount": "shipping",
                      "order_tax_amount": "tax",
                      "order_id": "transaction_id,order_id",
                      "order_total": "value",
                      "event_title": "event_name",
                      "tealium_event": "command_name",
                      "customer_id": "user_id,user_alias"]
        let expectedOutput: [String: Any] = ["item_id": ["ABC123"], "item_sku": ["ABC123"], "item_name": ["milk chocolate"], "item_brand": ["see's"], "price": ["19.99"], "quantity": ["1"], "user_id": "CUST234324", "user_alias": "CUST234324", "transaction_id": "ORD239847", "order_id": "ORD239847", "event_name": "ecommerce_purchase", "tax": "1.99", "shipping": "5.00"]
        let actualOutput: [String: Any] = Builder.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }
    
    func testMapPayloadWhenIncorrectSeparatorUsed() {
        let payload: [String: Any] = ["product_id": ["ABC123"], "product_name": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00"]
        let lookup = ["product_id": "item_id,item_sku",
                      "order_id": "transaction_id:order_id",
                      "customer_id": "user_id,user_alias"]
        let expectedOutput: [String: Any] = ["item_id": ["ABC123"], "item_sku": ["ABC123"], "user_id": "CUST234324", "user_alias": "CUST234324", "transaction_id:order_id": "ORD239847"]
        let actualOutput: [String: Any] = Builder.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }

    func testPerformanceWithObjectMap() {
        let lookup = [
            "content": "content",
            "content_type": "content_type",
            "coupon": "purchase.coupon",
            "product_brand": "event.item_brand",
            "product_category": "event.item_category",
            "product_id": "event.item_id",
            "product_list": "event.item_list",
            "product_location_id": "event.item_location_id",
            "product_name": "event.item_name",
            "product_variant": "event.item_variant",
            "campaign_medium": "event.medium",
            "product_unit_price": "event.price",
            "product_quantity": "event.quantity",
            "search_keyword": "event.search_term",
            "order_shipping_amount": "purchase.shipping",
            "order_tax_amount": "purchase.tax",
            "order_id": "purchase.transaction_id",
            "order_total": "purchase.value",
            "event_title": "event_name",
            "tealium_event": "command_name",
            "customer_id": "user.user_id"
        ]
        let payload: [String: Any] = [
            "content": "someContent",
            "content_type": "someContentType",
            "coupon": "someCoupon",
            "product_brand": ["someBrand"],
            "product_category": ["someCategory"],
            "product_id": ["someId"],
            "product_list": ["someList"],
            "product_location_id": "someLocationId",
            "product_name": ["someName"],
            "product_variant": ["someVariant"],
            "campaign_medium": "someMedium",
            "product_unit_price": [0.00],
            "product_quantity": [1],
            "search_keyword": "someSearchTerm",
            "order_shipping_amount": 5.00,
            "order_tax_amount": 3.00,
            "order_id": "ABC123",
            "order_total": 20.00,
            "event_title": "order",
            "tealium_event": "purchase",
            "customer_id": "cust1234"
        ]

        measure {
            let hello = Builder.objectMap(payload: payload, lookup: lookup)
            print(hello)
        }
    }

    func testPerformanceWithoutObjectMap() {
        let lookup = [
            "content": "content",
            "content_type": "content_type",
            "coupon": "coupon",
            "product_brand": "item_brand",
            "product_category": "item_category",
            "product_id": "item_id",
            "product_list": "item_list",
            "product_location_id": "item_location_id",
            "product_name": "item_name",
            "product_variant": "item_variant",
            "campaign_medium": "medium",
            "product_unit_price": "price",
            "product_quantity": "quantity",
            "search_keyword": "search_term",
            "order_shipping_amount": "shipping",
            "order_tax_amount": "tax",
            "order_id": "transaction_id",
            "order_total": "value",
            "event_title": "event_name",
            "tealium_event": "command_name",
            "customer_id": "user_id",
            "event_parameters": "event_parameters",
            "purchase_parameters": "purchase_parameters",
            "user_parameters": "user_parameters"
        ]
        let payload: [String: Any] = [
            "content": "someContent",
            "content_type": "someContentType",
            "user_parameters": ["customer_id": "cust1234"],
            "event_parameters": [
                "product_brand": ["someBrand"],
                "product_category": ["someCategory"],
                "product_id": ["someId"],
                "product_list": ["someList"],
                "product_location_id": "someLocationId",
                "product_name": ["someName"],
                "product_variant": ["someVariant"],
                "campaign_medium": "someMedium",
                "product_unit_price": [0.00],
                "product_quantity": [1],
                "search_keyword": "someSearchTerm"
            ],
            "purchase_parameters": [
                "coupon": "someCoupon",
                "order_shipping_amount": 5.00,
                "order_tax_amount": 3.00,
                "order_id": "ABC123",
                "order_total": 20.00
            ],
            "event_title": "order",
            "tealium_event": "purchase"
        ]

        measure {
            let hello = Builder.mapPayload(payload, lookup: lookup)
            print(hello)
        }
    }

    func testExtractCommandNameFromEvent() {
        let noConfig = TestTealiumHelper.loadStub(from: "allEventsCommands", type(of: self))
        let rcConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: noConfig)
        let trackData = TealiumEvent("launch").trackRequest.trackDictionary
        let commandName = Builder.extractCommandName(trackData: trackData,
                                         commandNames: rcConfig.apiCommands!)
        XCTAssertNotNil(commandName)
        XCTAssertEqual(commandName, "initialize,logevent")
    }

    func testExtractCommandNameFromAllEvents() {
        let noConfig = TestTealiumHelper.loadStub(from: "allEventsCommands", type(of: self))
        let rcConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: noConfig)
        let trackData = TealiumEvent("someOtherEvent").trackRequest.trackDictionary
        let commandName = Builder.extractCommandName(trackData: trackData,
                                         commandNames: rcConfig.apiCommands!)
        XCTAssertNotNil(commandName)
        XCTAssertEqual(commandName, "logevent")
    }

    func testExtractCommandNameFromAllViews() {
        let noConfig = TestTealiumHelper.loadStub(from: "allEventsCommands", type(of: self))
        let rcConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: noConfig)
        let trackData = TealiumView("someOtherEvent").trackRequest.trackDictionary
        let commandName = Builder.extractCommandName(trackData: trackData,
                                         commandNames: rcConfig.apiCommands!)
        XCTAssertNotNil(commandName)
        XCTAssertEqual(commandName, "logview")
    }

    func testExtractCommandNameNil() {
        let noConfig = TestTealiumHelper.loadStub(from: "exampleNoConfig", type(of: self))
        let rcConfig = try! JSONDecoder().decode(RemoteCommandConfig.self, from: noConfig)
        let trackData = TealiumEvent("missingEvent").trackRequest.trackDictionary
        let commandName = Builder.extractCommandName(trackData: trackData,
                                         commandNames: rcConfig.apiCommands!)
        XCTAssertNil(commandName)
    }

    func testKeysAndValuesMatchTrackData() {
        let keyValues = [("key", "value"),
                         ("key2", "value2")]
        let trackData: [String: Any] = ["key": "value", "key2": "value2", "key3": "value3", "key4": 2]
        XCTAssertTrue(Builder.keysAndValues(keyValues,
                                            matchTrackData: trackData))
    }

    func testKeysAndValuesMatchTrackDataWithInt() {
        let keyValues = [("key", "value"),
                         ("key4", "2")]
        let trackData: [String: Any] = ["key": "value", "key2": "value2", "key3": "value3", "key4": 2]
        XCTAssertTrue(Builder.keysAndValues(keyValues,
                                            matchTrackData: trackData))
    }

    func testKeysAndValuesMatchTrackDataWithDouble() {
        let keyValues = [("key", "value"),
                         ("key4", "3.0")]
        let trackData: [String: Any] = ["key": "value", "key2": "value2", "key3": "value3", "key4": Double(3.0)]
        XCTAssertTrue(Builder.keysAndValues(keyValues,
                                            matchTrackData: trackData))
    }

    func testKeysAndValuesMatchTrackDataWrongValue() {
        let keyValues = [("key", "value"),
                         ("key2", "value3")]
        let trackData: [String: Any] = ["key": "value", "key2": "value2", "key3": "value3", "key4": 2]
        XCTAssertFalse(Builder.keysAndValues(keyValues,
                                            matchTrackData: trackData))
    }

    func testKeysAndValuesMatchTrackDataWithMissingKey() {
        let keyValues = [("key", "value"),
                         ("key5", "anything")]
        let trackData: [String: Any] = ["key": "value", "key2": "value2", "key3": "value3", "key4": 2]
        XCTAssertFalse(Builder.keysAndValues(keyValues,
                                            matchTrackData: trackData))
    }

    func testPayloadWithStatics() {
        let trackData = ["tealium_event": "some_event", "someKey": "someValue"]
        let statics = [
            "some_event": [ "staticKey1": "staticValue1"],
            "someKey:someValue": [ "staticKey2": "staticValue2"],
            "someKey:someValue,tealium_event:some_event": [ "staticKey3": "staticValue3"]
        ]
        let payload = Builder.payloadWithStatics(trackData: trackData, statics: statics)
        for keyValue in trackData {
            XCTAssertEqual(payload[keyValue.key] as? String, keyValue.value)
        }
        for staticKeyValues in statics {
            for staticValue in staticKeyValues.value {
                XCTAssertEqual(payload[staticValue.key] as? String, staticValue.value)
            }
        }
    }

    func testPayloadWithNonMatchingStatics() {
        let trackData = ["tealium_event": "some_event", "someKey": "someValue"]
        let statics = [
            "some_event_missing": [ "staticKey1": "staticValue1"],
            "someKey_missing:someValue": [ "staticKey2": "staticValue2"],
            "someKey:someValue,tealium_event:some_event,missingKey:anyValue": [ "staticKey3": "staticValue3"]
        ]
        let payload = Builder.payloadWithStatics(trackData: trackData, statics: statics)
        XCTAssertEqual(trackData, payload as? [String: String])
    }

    func testSplitKeysAndValuesToMatchDefaultToTealiumEvent() {
        let split = Builder.splitKeysAndValuesToMatch("someEvent")
        XCTAssertEqual(split[0].0, "tealium_event")
        XCTAssertEqual(split[0].1, "someEvent")
        XCTAssertEqual(split.count, 1)
    }

    func testSplitKeysAndValuesToMatchKeyValue() {
        let split = Builder.splitKeysAndValuesToMatch("someKey:someValue")
        XCTAssertEqual(split[0].0, "someKey")
        XCTAssertEqual(split[0].1, "someValue")
        XCTAssertEqual(split.count, 1)
    }

    func testSplitKeysAndValuesToMatchKeyValuesCommaSeparated() {
        let split = Builder.splitKeysAndValuesToMatch("someKey1:someValue1,someKey2:someValue2")
        XCTAssertEqual(split[0].0, "someKey1")
        XCTAssertEqual(split[0].1, "someValue1")
        XCTAssertEqual(split[1].0, "someKey2")
        XCTAssertEqual(split[1].1, "someValue2")
        XCTAssertEqual(split.count, 2)
    }

    func testSplitKeysAndValuesToMatchKeyValuesCommaSeparatedAndDefaultEvent() {
        let split = Builder.splitKeysAndValuesToMatch("someKey1:someValue1,someKey2:someValue2,someEvent")
        XCTAssertEqual(split[0].0, "someKey1")
        XCTAssertEqual(split[0].1, "someValue1")
        XCTAssertEqual(split[1].0, "someKey2")
        XCTAssertEqual(split[1].1, "someValue2")
        XCTAssertEqual(split[2].0, "tealium_event")
        XCTAssertEqual(split[2].1, "someEvent")
        XCTAssertEqual(split.count, 3)
    }
}
