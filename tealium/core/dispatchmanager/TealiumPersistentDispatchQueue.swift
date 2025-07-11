//
//  TealiumPersistentDispatchQueue.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumPersistentDispatchQueue {

    var diskStorage: TealiumDiskStorageProtocol!
    public private(set) var currentEvents: Int = 0

    public init(diskStorage: TealiumDiskStorageProtocol) {
        self.diskStorage = diskStorage

        if let totalEvents = self.peek()?.count {
            currentEvents = totalEvents
        }

    }

    func appendDispatch(_ dispatch: TealiumTrackRequest) {
        currentEvents += 1
        diskStorage.append(dispatch, completion: nil)
    }

    func saveAndOverwrite(_ dispatches: [TealiumTrackRequest]) {
        currentEvents = dispatches.count
        diskStorage.save(dispatches, completion: nil)
    }

    func peek() -> [TealiumTrackRequest]? {
        guard let dispatches = dequeueDispatches(clear: false) else {
            return nil
        }
        currentEvents = dispatches.count
        return dispatches
    }

    func dequeueDispatches(clear clearQueue: Bool? = true) -> [TealiumTrackRequest]? {
        guard let queuedDispatches = diskStorage.retrieve(as: [TealiumTrackRequest].self) else {
            return nil
        }

        if clearQueue == true {
            self.currentEvents = 0
            diskStorage.delete(completion: nil)
        }

        return queuedDispatches.sorted()
    }

    func removeOldDispatches(_ maxQueueSize: Int,
                             since: Date? = nil) {
        // save dispatch can only happen once queue is initialized
        guard let currentData = peek() else {
            return
        }

        // note: any completion blocks will be ignored for now, since we can only persist Dictionaries
        var newData = currentData
        var hasModified = false
        let totalDispatches = newData.count
        if totalDispatches >= maxQueueSize, maxQueueSize > 0 {
            // take suffix to get most recent events and discard oldest first
            // want to remove only 1 event, so if current total is 20, max is 20, we want to be
            // left with 19 elements => 20 - (20-1) = 19
            let slice = newData.suffix(from: totalDispatches - maxQueueSize)
            newData = Array(slice)
            hasModified = true
        }

        if let sinceDate = since {
            newData = newData.filter {
                guard let timestamp = $0.trackDictionary[TealiumDataKey.timestampUnix] as? String else {
                    return true
                }

                guard let interval = TimeInterval(timestamp) else {
                    return true
                }

                hasModified = true
                let trackDate = Date(timeIntervalSince1970: interval)

                return trackDate > sinceDate
            }
        }

        if hasModified {
            saveAndOverwrite(newData)
        }
    }

    func clearNonAuditEvents() {
        guard let requests = peek(), requests.count > 0 else {
            return
        }
        let auditEvents = requests.filter { $0.containsAuditEvent }
        if auditEvents.count > 0 {
            saveAndOverwrite(auditEvents)
        } else {
            currentEvents = 0
            diskStorage.delete(completion: nil)
        }
    }

}
