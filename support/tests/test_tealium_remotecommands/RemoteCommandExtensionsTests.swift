//
//  RemoteCommandExtensionsTests.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

@testable import TealiumCore
@testable import TealiumRemoteCommands
import XCTest

class RemoteCommandExtensionsTests: XCTestCase {

    var testBundle: Bundle!

    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: type(of: self))
    }

    override func tearDown() {
        super.tearDown()
    }

    func testRemoveCommand() {
        var commands = [RemoteCommandProtocol]()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        let webViewCommand = RemoteCommand(commandId: "webviewTest123", description: "test") { _ in
            // ...
        }
        commands = [command, webViewCommand]
        commands.removeCommand("test123")
        commands.removeCommand("webviewTest123")
        XCTAssertTrue(commands.count == 0)
    }

    func testAddRemoteCommand() {
        let testHelper = TestTealiumHelper()
        let config = testHelper.getConfig()
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        let webViewCommand = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        config.addRemoteCommand(webViewCommand)
        config.addRemoteCommand(command)
        XCTAssertTrue(config.remoteCommands?.count == 2)
    }

    func testIsValidURL() {
        let validURLString = "https://www.tealium.com"
        let anotherValidURLString = "https://www.tealium.com/?test=test&key=value"
        let invalidURLString = "😫😫😫😫😫"
        let anotherInvalidURLString = "&%*#*(#@($)#*#@(&%(&@#%(&$3253"
        XCTAssertTrue(validURLString.isValidUrl)
        XCTAssertTrue(anotherValidURLString.isValidUrl)
        XCTAssertFalse(invalidURLString.isValidUrl)
        XCTAssertFalse(anotherInvalidURLString.isValidUrl)
    }

    func testCacheBuster() {
        let urlString = "https://www.tealium.com"
        XCTAssertTrue(urlString.cacheBuster.starts(with: "https://www.tealium.com?_cb="))
    }

    func testMapPayload() {
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
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
        let actualOutput: [String: Any] = command.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }

    func testMapPayloadWithMultipleMappings() {
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
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
        let actualOutput: [String: Any] = command.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }

    func testMapPayloadWhenIncorrectSeparatorUsed() {
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
        let payload: [String: Any] = ["product_id": ["ABC123"], "product_name": ["milk chocolate"], "product_brand": ["see's"], "product_unit_price": ["19.99"], "product_quantity": ["1"], "customer_id": "CUST234324", "customer_full_name": "Christina Test", "order_id": "ORD239847", "event_title": "ecommerce_purchase", "order_tax_amount": "1.99", "order_shipping_amount": "5.00"]
        let lookup = ["product_id": "item_id,item_sku",
                      "order_id": "transaction_id:order_id",
                      "customer_id": "user_id,user_alias"]
        let expectedOutput: [String: Any] = ["item_id": ["ABC123"], "item_sku": ["ABC123"], "user_id": "CUST234324", "user_alias": "CUST234324", "transaction_id:order_id": "ORD239847"]
        let actualOutput: [String: Any] = command.mapPayload(payload, lookup: lookup)

        XCTAssertTrue(NSDictionary(dictionary: actualOutput).isEqual(to: expectedOutput))
    }

    func testPerformanceWithObjectMap() {
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
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
            let hello = command.objectMap(payload: payload, lookup: lookup)
            print(hello)
        }
    }

    func testPerformanceWithoutObjectMap() {
        let command = RemoteCommand(commandId: "test123", description: "test") { _ in
            // ...
        }
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
            let hello = command.mapPayload(payload, lookup: lookup)
            print(hello)
        }

    }

}
