//
//  TealiumLifecycleEventsDelegate.swift
//  tealium-swift
//
//  Created by Craig Rouse on 28/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumLifecycleEvents {

    /// Notifies listeners of a sleep event.
    func sleep()

    /// Notifies listeners of a wake event.
    func wake()

    /// Notifies listeners of a launch event￼.
    /// 
    /// - Parameter date: `Date` the launch occurred
    func launch(at date: Date)

}
