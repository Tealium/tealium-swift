//
//  AnyCodableTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/08/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import TealiumCore

class AnyCodableTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBool() throws {
        try encodeTest(value: true)
        try encodeTest(value: false)
    }
    
    func testString() throws {
        try encodeTest(value: "text")
        try encodeTest(value: "")
    }
    
    func testInt() throws {
        try encodeTest(value: 0)
        try encodeTest(value: 12)
        try encodeTest(value: -1)
        try encodeTest(value: Int32(20))
        try encodeTest(value: Int64(2))
        try encodeTest(value: Int.max)
        try encodeTest(value: Int.min)
    }
    
    func testDouble() throws {
        try encodeTest(value: Double.zero)
        try encodeTest(value: Double(3.4))
        try encodeTest(value: Double(-23.5))
        try encodeTest(value: Double.infinity)
        try encodeTest(value: Double.greatestFiniteMagnitude)
    }
    
    func testDoubleNan() throws {
        let nanData = try encode(Double.nan)
        let nanRes: Double = try decode(nanData)
        XCTAssertTrue(nanRes.isNaN)
    }
    
    func testFloat() throws {
        try encodeTest(value: Float.zero)
        try encodeTest(value: Float(3.4))
        try encodeTest(value: Float(-23.5))
        try encodeTest(value: Float.infinity)
        try encodeTest(value: Float.greatestFiniteMagnitude)
    }
    
    func testFloatNan() throws {
        let nanData = try encode(Float.nan)
        let nanRes: Float = try decode(nanData)
        XCTAssertTrue(nanRes.isNaN)
    }
    
    func testNSNumber() throws {
        try nsNumberTest(value: true)
        try nsNumberTest(value: false)
        try nsNumberTest(value: 4)
        try nsNumberTest(value: Double(2.2))
        try nsNumberTest(value: Float(4.5))
        try nsNumberTest(value: Double.greatestFiniteMagnitude)
        try nsNumberTest(value: Double.infinity)
        try nsNumberTest(value: Float.greatestFiniteMagnitude)
        try nsNumberTest(value: Float.infinity)
        try nsNumberTest(value: UInt(32))
        try nsNumberTest(value: UInt32(2))
        try nsNumberTest(value: Int8(3))
        try nsNumberTest(value: UInt16(17))
        try nsNumberTest(value: Int16(6))
    }
    
    func testDate() throws {
        try encodeTest(value: Date())
    }
    
    func testArray() throws {
        try encodeTest(value: [Int]())
        try encodeTest(value: [1,2,3])
        try encodeTest(value: ["1","2","3"])
        try encodeTest(value: [Date()])
    }
    
    func testNil() throws {
        let codable = AnyCodable(nil)
        try encodeAnyCodableTest(codable)
    }
    
    func testVoid() throws {
        let codable = AnyCodable(())
        try encodeAnyCodableTest(codable)
    }
    
    func testNSNull() throws {
        let codable = AnyCodable(NSNull())
        try encodeAnyCodableTest(codable)
    }
    
    private func nsNumberTest<T: Decodable & Equatable>(value: T) throws {
        guard let number = value as? NSNumber else {
            throw NSError(domain: "Invalid Argument", code: 1, userInfo: nil)
        }
        let data = try encode(number)
        let res: T = try decode(data)
        XCTAssertEqual(value, res)
    }
    
    private func encodeTest<T: Decodable & Equatable>(value: T) throws {
        let data = try encode(value)
        let res: T = try decode(data)
        XCTAssertEqual(value, res)
        try encodeAnyCodableTest(AnyCodable(value))
    }
    
    private func encodeAnyCodableTest(_ codable: AnyCodable) throws {
        let data = try encodeAnyCodable(codable)
        let anyCodableRes = try decodeAnyCodable(data)
        XCTAssertEqual(codable, anyCodableRes)
    }
    
    private func encode(_ value: Any) throws -> Data {
        return try encodeAnyCodable(AnyCodable(value))
    }
    
    private func decode<T: Decodable>(_ data: Data) throws -> T {
        return try Tealium.jsonDecoder.decode(T.self, from: data)
    }
    
    private func encodeAnyCodable(_ codable: AnyCodable) throws -> Data {
        return try Tealium.jsonEncoder.encode(codable)
    }
    
    private func decodeAnyCodable(_ data: Data) throws -> AnyCodable {
        return try Tealium.jsonDecoder.decode(AnyCodable.self, from: data)
    }

}
