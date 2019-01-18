//
//  TealiumRegistration.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/17/19.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import UIKit

public protocol TealiumRegistration {
    func registerPushToken(_ token: String)
    
    func userNotificationCenter(_ center: UNUserNotificationCenter)
}
