//
//  Expiry.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public enum Expiry {
    case session
    case untilRestart
    case forever
    case after(Date)
    case afterCustom((TimeUnit, Int))

    public var date: Date {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        switch self {
        case .after(let date):
            return date
        case .session:
            components.setValue(TealiumValue.defaultMinutesBetweenSession, for: .minute)
            return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)!
        case .untilRestart:
            return currentDate
        case .forever:
            components.setValue(100, for: .year)
            return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)!
        case .afterCustom(let (unit, value)):
            components.setValue(value, for: unit.component)
            return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)!
        }
    }

}

public enum TimeUnit {
    case minutes
    case hours
    case days
    case months
    case years

    public var component: Calendar.Component {
        switch self {
        case .minutes:
            return .minute
        case .hours:
            return .hour
        case .days:
            return .day
        case .months:
            return .month
        case .years:
            return .year
        }
    }
}
