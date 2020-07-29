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

public class TealiumPersistentDataStorage: Codable {
    var data: AnyCodable
    lazy var isEmpty: Bool = {
        TealiumQueues.backgroundConcurrentQueue.read { [weak self] in
            guard let totalValues = (self?.data.value as? [String: Any])?.count else {
                return true
            }
            return totalValues == 0
        }
    }()

    public init() {
        self.data = [String: Any]().codable
    }

    public func values() -> [String: Any]? {
        TealiumQueues.backgroundConcurrentQueue.read { [weak self] in
            guard let self = self else {
                return nil
            }
            return self.data.value as? [String: Any]
        }
    }

    public func add(data: [String: Any]) {
        var newData = [String: Any]()
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            if let existingData = self.data.value as? [String: Any] {
                newData += existingData
            }
            newData += data
            self.data = newData.codable
        }
    }

    public func delete(forKey key: String) {
        TealiumQueues.backgroundConcurrentQueue.write { [weak self] in
            guard let self = self else {
                return
            }
            guard var data = self.data.value as? [String: Any] else {
                return
            }
            data[key] = nil
            self.data = data.codable
        }
    }

}
