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
    
    func testNan() throws {
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
    
    func testNSNumber() throws {
        let data = try encode(NSNumber(true))
        let res: Bool = try decode(data)
        let text = String(data: data, encoding: .utf8)
        XCTAssertTrue(res)
        XCTAssertEqual(text, String(describing: true))
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
    
    
    func testVoid() throws {
        // ???
    }
    
    func testNSNull() throws {
        // ???
    }
    
    func encodeTest<T: Decodable & Equatable>(value: T) throws {
        let data = try encode(value)
        let res: T = try decode(data)
        XCTAssertEqual(value, res)
    }
    
    private func encode(_ value: Any) throws -> Data {
        return try Tealium.jsonEncoder.encode(AnyCodable(value))
    }
    
    private func decode<T: Decodable>(_ data: Data) throws -> T {
        return try Tealium.jsonDecoder.decode(T.self, from: data)
    }

}
