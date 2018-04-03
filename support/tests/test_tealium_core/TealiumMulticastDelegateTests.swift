//
//  TealiumMulticastDelegateTests.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/30/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import XCTest
@testable import Tealium

class TealiumMulticastDelegateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAddReferenceTypes() {
        let multicastDelegate = TealiumMulticastDelegate<TealiumDeviceData>()
        let deviceData1 = TealiumDeviceData()
        let deviceData2 = TealiumDeviceData()
        multicastDelegate.add(deviceData1)
        multicastDelegate.add(deviceData2)

        XCTAssertEqual(2, multicastDelegate.all().count)
    }

    func testRemoveRemovesCorrectElement() {
        let multicastDelegate = TealiumMulticastDelegate<TealiumAppData>()
        let appData1 = TealiumAppData()
        appData1.add(data: ["key": "1"])
        let appData2 = TealiumAppData()
        appData2.add(data: ["key": "2"])
        multicastDelegate.add(appData1)
        multicastDelegate.add(appData2)

        multicastDelegate.remove(appData2)
        let result = multicastDelegate.all().first

        XCTAssertEqual(1, multicastDelegate.count)

        guard let resultAppData = result?.value as? TealiumAppData else {
            return XCTFail("Not the correct type")
        }
        guard let value = resultAppData.getData().first else {
            return XCTFail("no items")
        }

        XCTAssertEqual("1", value.value as? String)
        XCTAssertEqual("key", value.key)
    }

    func testRemoveAllRemovesAllElements() {
        let multicastDelegate = TealiumMulticastDelegate<TealiumAppData>()
        let appData1 = TealiumAppData()
        let appData2 = TealiumAppData()
        let appData3 = TealiumAppData()
        multicastDelegate.add(appData1)
        multicastDelegate.add(appData2)
        multicastDelegate.add(appData3)

        multicastDelegate.removeAll()

        XCTAssertEqual(0, multicastDelegate.count)
    }

    func testInvokeCallsFunctionInCollection() {
        let multicastDelegate = TealiumMulticastDelegate<TealiumDeviceData>()
        let deviceData1 = TealiumDeviceData()
        let deviceData2 = TealiumDeviceData()
        let deviceData3 = TealiumDeviceData()
        multicastDelegate.add(deviceData1)
        multicastDelegate.add(deviceData2)
        multicastDelegate.add(deviceData3)

        var models = [String]()
        multicastDelegate.invoke { deviceData in
            let result = deviceData.basicModel()
            models.append(result)
        }

        XCTAssertEqual(3, models.count)
    }
}
