//
//  TealiumPersistentDispatchQueue.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/04/2018.
//  Copyright © 2018 Tealium. All rights reserved.
//

import Foundation
class TealiumPersistentDispatchQueue {

    static var queueStorage = UserDefaults.standard

    let readWriteQueue = ReadWrite("\(TealiumDispatchQueueConstants.moduleName).label")

    let config: TealiumConfig

    lazy var storageKey: String = TealiumPersistentDispatchQueue.generateStorageKey(self.config)

    public init(_ config: TealiumConfig) {
        self.config = config
        initializeQueue()
    }

    // used only for unit tests
    convenience init(_ config: TealiumConfig, userDefaultsMock: UserDefaults) {
        TealiumPersistentDispatchQueue.queueStorage = userDefaultsMock
        self.init(config)
    }

    class func generateStorageKey(_ config: TealiumConfig) -> String {
        return "\(config.account).\(config.profile).\(config.environment).\(TealiumDispatchQueueConstants.moduleName)"
    }

    func initializeQueue() {
        // queue already initialized
        if let _ = TealiumPersistentDispatchQueue.queueStorage.object(forKey: storageKey) as? [[String: Any]] {
            return
        }
        // init with blank data
        let blankData = [[String: Any]]()
        TealiumPersistentDispatchQueue.queueStorage.set(blankData, forKey: storageKey)
    }

    func saveDispatch(_ dispatch: TealiumTrackRequest) {
        // save dispatch can only happen once queue is initialized
        guard let currentData = dequeueDispatches() else {
            return
        }

        // note: any completion blocks will be ignored for now, since we can only persist Dictionaries in UserDefaults
        var newData = currentData
        newData.append(dispatch.data)
        readWriteQueue.write {
            TealiumPersistentDispatchQueue.queueStorage.set(newData, forKey: self.storageKey)
        }
    }

    func peek() -> [[String: Any]]? {
        return dequeueDispatches(clear: false)
    }

    func dequeueDispatches(clear clearQueue: Bool? = true) -> [[String: Any]]? {
        var queuedDispatches: [[String: Any]]?
        readWriteQueue.read {
            if let dispatches = TealiumPersistentDispatchQueue.queueStorage.array(forKey: self.storageKey) as? [[String: Any]] {
                // clear persistent queue
                if clearQueue == true {
                    self.clearQueue()
                }
                queuedDispatches = dispatches
            }
        }
        return queuedDispatches
    }

    func removeOldDispatches(_ maxQueueSize: Int) {
        // save dispatch can only happen once queue is initialized
        guard let currentData = self.peek() else {
            return
        }

        // note: any completion blocks will be ignored for now, since we can only persist Dictionaries in UserDefaults
        var newData = currentData
        let totalDispatches = newData.count
        if totalDispatches == maxQueueSize {
            // take suffix to get most recent events and discard oldest first
            // want to remove only 1 event, so if current total is 20, max is 20, we want to be
            // left with 19 elements => 20 - (20-1) = 19
            let slice = newData.suffix(from: totalDispatches - (maxQueueSize - 1))
            newData = Array(slice)
            readWriteQueue.write {
                TealiumPersistentDispatchQueue.queueStorage.set(newData, forKey: self.storageKey)
            }
        }
    }

    func clearQueue() {
        readWriteQueue.write {
            let blankData = [[String: Any]]()
            TealiumPersistentDispatchQueue.queueStorage.set(blankData, forKey: self.storageKey)
        }
    }

}
