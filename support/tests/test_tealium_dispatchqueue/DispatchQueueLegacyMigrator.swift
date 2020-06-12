//
//  MockMigrator.swift
//  tealium-swift
//
//  Created by Craig Rouse on 03/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumDispatchQueue

class MockTealiumMigratorWithData: TealiumLegacyMigratorProtocol {
    static func getLegacyData(forModule module: String) -> [String: Any]? {
        return nil
    }

    static func getLegacyDataArray(forModule module: String) -> [[String: Any]]? {
        return TealiumPersistentQueueTests.mockData
    }

}

class MockTealiumMigratorNoData: TealiumLegacyMigratorProtocol {
    static func getLegacyData(forModule module: String) -> [String: Any]? {
        return nil
    }

    static func getLegacyDataArray(forModule module: String) -> [[String: Any]]? {
        return nil
    }

}
