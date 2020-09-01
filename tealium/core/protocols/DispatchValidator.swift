//
//  DispatchValidatorProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 23/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DispatchValidator {
    var id: String { get }
    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?)
    func shouldDrop(request: TealiumRequest) -> Bool
    func shouldPurge(request: TealiumRequest) -> Bool
}
