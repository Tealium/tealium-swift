//
//  TealiumVolatileDataConstants.swift
//  TealiumVolatileData
//
//  Created by Craig Rouse on 24/09/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if volatiledata
import TealiumCore
#endif

public enum TealiumVolatileDataKey {
    static let moduleName = "volatiledata"
    static let random = TealiumKey.random
    public static let timestampEpoch = "tealium_timestamp_epoch"
    static let timestampLegacy = "event_timestamp_iso"
    static let timestamp = "timestamp"
    static let timestampLocalLegacy = "event_timestamp_local_iso"
    static let timestampLocal = "timestamp_local"
    static let timestampOffsetLegacy = "event_timestamp_offset_hours"
    static let timestampOffset = "timestamp_offset"
    static let timestampUnixMillisecondsLegacy = "event_timestamp_unix_millis"
    static let timestampUnixMilliseconds = "timestamp_unix_milliseconds"
    static let timestampUnixLegacy = "event_timestamp_unix"
    static let timestampUnix = TealiumKey.timestampUnix
}
