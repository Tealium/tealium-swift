//
//  DiskErrors.swift
//  TealiumSwift
//
//  Created by Craig Rouse on 29/11/2019.
//  Copyright © 2019 Tealium. All rights reserved.
//

import Foundation

public struct DiskError: Error {
    enum ErrorKind: TealiumErrorEnum {
        case noFileFound
        case serialization
        case deserialization
        case invalidFileName
        case couldNotAccessTemporaryDirectory
        case couldNotAccessUserDomainMask
        case couldNotAccessSharedContainer
    }

    let kind: ErrorKind
    let errorInfo: [String: Any]

    var localizedDescription: String? {
        return kind.localizedDescription + String(describing: errorInfo)
    }
}
