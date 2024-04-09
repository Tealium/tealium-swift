//
//  ErrorCooldown.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 09/04/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ErrorCooldownProtocol: AnyObject {
    var maxInterval: Double { get set }
    func isInCooldown(lastFetch: Date) -> Bool
    func newCooldownEvent(error: Error?)
}

class ErrorCooldown: ErrorCooldownProtocol {
    let baseInterval: Double?
    var maxInterval: Double
    private var lastCallError: Error?
    private var consecutiveErrorsCount = 0

    init(baseInterval: Double?, maxInterval: Double) {
        self.baseInterval = baseInterval
        self.maxInterval = maxInterval
    }

    var cooldownInterval: Double? {
        guard let cooldownBaseInterval = baseInterval else {
            return nil
        }
        return min(maxInterval, cooldownBaseInterval * Double(consecutiveErrorsCount))
    }

    func isInCooldown(lastFetch: Date) -> Bool {
        guard lastCallError != nil else {
            return false
        }
        guard let cooldownInterval = cooldownInterval,
              let cooldownEndDate = lastFetch.addSeconds(cooldownInterval) else {
            return false
        }
        return cooldownEndDate > Date()
    }

    func newCooldownEvent(error: Error?) {
        if let _ = error {
            consecutiveErrorsCount += 1
        }
        lastCallError = error
    }
}
