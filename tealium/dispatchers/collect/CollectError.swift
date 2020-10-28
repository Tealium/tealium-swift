//
//  CollectError.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public enum CollectError: String, LocalizedError {
    case collectNotInitialized
    case unknownResponseType
    case xErrorDetected
    case non200Response
    case noDataToTrack
    case unknownIssueWithSend
    case invalidDispatchURL
    case trackNotApplicableForCollectModule
    case invalidBatchRequest

    public var errorDescription: String? {
        return self.rawValue
    }

}
