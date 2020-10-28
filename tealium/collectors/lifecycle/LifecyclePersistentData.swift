//
//  LifecyclePersistentData.swift
//  tealium-swift
//
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumCore
#endif

open class LifecyclePersistentData {

    let diskStorage: TealiumDiskStorageProtocol

    init(diskStorage: TealiumDiskStorageProtocol,
         uniqueId: String? = nil) {
        self.diskStorage = diskStorage
    }

    func load() -> Lifecycle? {
        return diskStorage.retrieve(as: Lifecycle.self)
    }

    func save(_ lifecycle: Lifecycle) -> (success: Bool, error: Error?) {
        diskStorage.save(lifecycle, completion: nil)
        return (true, nil)
    }

}
