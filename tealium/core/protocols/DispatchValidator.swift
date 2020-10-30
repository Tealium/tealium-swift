//
//  DispatchValidator.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DispatchValidator {
    var id: String { get }
    func shouldQueue(request: TealiumRequest) -> (Bool, [String: Any]?)
    func shouldDrop(request: TealiumRequest) -> Bool
    func shouldPurge(request: TealiumRequest) -> Bool
}
