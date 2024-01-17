//
//  CollectError.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public enum CollectError: TealiumErrorEnum {
    case collectNotInitialized
    case unknownResponseType
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
    case invalidDispatchURL
    case trackNotApplicableForCollectModule
    case invalidBatchRequest
}
