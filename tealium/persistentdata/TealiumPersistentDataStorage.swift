//
//  TealiumPersistentDataStorage.swift
//  tealium-swift
//
//  Created by Craig Rouse on 19/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if persistentdata
import TealiumCore
#endif

//// MARK:
//// MARK: PERSISTENT DATA

public struct TealiumPersistentDataStorage: Codable {
    var data: AnyCodable
    lazy var isEmpty: Bool = {
        guard let totalValues = (self.data.value as? [String: Any])?.count else {
            return true
        }
        return !(totalValues > 0)
    }()

    public init() {
        self.data = [String: Any]().codable
    }

    public func values() -> [String: Any]? {
        return self.data.value as? [String: Any]
    }

    public mutating func add(data: [String: Any]) {
        var newData = [String: Any]()

        if let existingData = self.data.value as? [String: Any] {
            newData += existingData
        }

        newData += data
        self.data = newData.codable
    }

    public mutating func delete(forKey key: String) {
        guard var data = self.data.value as? [String: Any] else {
            return
        }

        data[key] = nil

        self.data = data.codable
    }

}
