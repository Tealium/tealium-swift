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

    public var date: Date? {
        switch self {
        case .after(let date):
            return date
        case .session, .forever:
            return distantDate()
        case .untilRestart:
            return Date()
        case .afterCustom(let (unit, value)):
            return dateWith(unit: unit, value: value)
        }
    }
    
    private func dateWith(unit: TimeUnit, value: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar.autoupdatingCurrent
        let currentDate = Date()
        components.setValue(value, for: unit.component)
        return Calendar(identifier: .gregorian).date(byAdding: components, to: currentDate)
    }
    
    private func distantDate() -> Date? {
        dateWith(unit: .years, value: 100)
    }
    
    func isSession() -> Bool {
        switch self {
        case .session:
            return true
        default:
            return false
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
