//
//  MockAppDataDiskStorage.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

@testable import TealiumCore
import XCTest

class MockAppDataDiskStorage: MockTealiumDiskStorage {

    func reset() {
        saveCount = 0
        retrieveCount = 0
        saveToDefaultsCount = 0
        deleteCount = 0
        storedData = nil
    }
}
